"""
Graph-based anomaly detection using NetworkX.

Builds a bipartite graph: UPI IDs <-> Merchants, then detects:
1. Single UPI ID linked to unusually many merchants (money mule pattern)
2. Clusters of UPI IDs sharing suspicious connectivity patterns
3. Merchant nodes with abnormal in-degree (fake storefront networks)

This is the "stretch goal" that elevates the scoring beyond simple rule-matching.
"""

import json
from collections import defaultdict
from pathlib import Path

import networkx as nx
from networkx.algorithms import bipartite

DATA_DIR = Path(__file__).parent / "data"

_graph_cache: nx.Graph | None = None
_anomaly_cache: dict | None = None

# Thresholds for anomaly detection
UPI_MULTI_MERCHANT_THRESHOLD = 3  # UPI linked to 3+ merchants is suspicious
MERCHANT_MULTI_UPI_THRESHOLD = 4  # Merchant with 4+ UPI IDs is suspicious
CLUSTERING_THRESHOLD = 0.7        # High local clustering = coordinated network


def build_graph() -> nx.Graph:
    """
    Build a bipartite graph from the QR registry data.

    Nodes: UPI IDs (type='upi') and Merchants (type='merchant')
    Edges: A UPI ID is linked to a merchant via QR registration
    """
    global _graph_cache
    if _graph_cache is not None:
        return _graph_cache

    qr_path = DATA_DIR / "qr_registry.json"
    merchants_path = DATA_DIR / "merchants.json"

    with open(qr_path) as f:
        qr_entries = json.load(f)
    with open(merchants_path) as f:
        merchants = json.load(f)

    merchant_map = {m["id"]: m for m in merchants}
    G = nx.Graph()

    for entry in qr_entries:
        upi_id = entry["upi_id"]
        merchant_id = entry["merchant_id"]

        # Add UPI node
        if not G.has_node(upi_id):
            G.add_node(upi_id, node_type="upi", bipartite=0)

        # Add Merchant node
        if not G.has_node(merchant_id):
            merchant_info = merchant_map.get(merchant_id, {})
            G.add_node(
                merchant_id,
                node_type="merchant",
                bipartite=1,
                name=merchant_info.get("name", "Unknown"),
                is_verified=merchant_info.get("is_verified", False),
            )

        # Add edge
        G.add_edge(upi_id, merchant_id, is_fraudulent=entry.get("is_fraudulent", False))

    _graph_cache = G
    return G


def detect_anomalies() -> dict:
    """
    Run all anomaly detection algorithms on the graph.

    Returns:
        {
            "multi_merchant_upis": [{"upi_id": str, "merchant_count": int, "merchants": [...]}],
            "multi_upi_merchants": [{"merchant_id": str, "upi_count": int, "upi_ids": [...]}],
            "suspicious_clusters": [{"nodes": [...], "density": float}],
            "high_betweenness_nodes": [{"node": str, "betweenness": float}],
        }
    """
    global _anomaly_cache
    if _anomaly_cache is not None:
        return _anomaly_cache

    G = build_graph()

    upi_nodes = [n for n, d in G.nodes(data=True) if d.get("node_type") == "upi"]
    merchant_nodes = [n for n, d in G.nodes(data=True) if d.get("node_type") == "merchant"]

    # 1. UPI IDs connected to multiple merchants (money mule / QR-jacking pattern)
    multi_merchant_upis = []
    for upi in upi_nodes:
        neighbors = list(G.neighbors(upi))
        if len(neighbors) >= UPI_MULTI_MERCHANT_THRESHOLD:
            multi_merchant_upis.append({
                "upi_id": upi,
                "merchant_count": len(neighbors),
                "merchants": neighbors,
            })

    multi_merchant_upis.sort(key=lambda x: x["merchant_count"], reverse=True)

    # 2. Merchants with multiple UPI IDs pointing to them (fake storefront detection)
    multi_upi_merchants = []
    for merchant in merchant_nodes:
        neighbors = list(G.neighbors(merchant))
        if len(neighbors) >= MERCHANT_MULTI_UPI_THRESHOLD:
            multi_upi_merchants.append({
                "merchant_id": merchant,
                "merchant_name": G.nodes[merchant].get("name", "Unknown"),
                "upi_count": len(neighbors),
                "upi_ids": neighbors,
            })

    multi_upi_merchants.sort(key=lambda x: x["upi_count"], reverse=True)

    # 3. Connected components analysis — isolated clusters suggest coordinated fraud
    suspicious_clusters = []
    for component in nx.connected_components(G):
        subgraph = G.subgraph(component)
        if len(component) >= 4:
            density = nx.density(subgraph)
            if density >= CLUSTERING_THRESHOLD:
                suspicious_clusters.append({
                    "nodes": list(component),
                    "size": len(component),
                    "density": round(density, 3),
                })

    # 4. Betweenness centrality — nodes that bridge many paths are potential fraud hubs
    betweenness = nx.betweenness_centrality(G)
    high_betweenness = [
        {"node": node, "node_type": G.nodes[node].get("node_type"), "betweenness": round(score, 4)}
        for node, score in sorted(betweenness.items(), key=lambda x: x[1], reverse=True)[:10]
        if score > 0.01
    ]

    # 5. Projected graph: UPI-to-UPI connections (two UPIs linked if they share a merchant)
    # High degree in projection = coordinated fraud ring
    if upi_nodes and merchant_nodes:
        try:
            upi_projection = bipartite.projected_graph(G, upi_nodes)
            fraud_rings = []
            for component in nx.connected_components(upi_projection):
                if len(component) >= 3:
                    sub = upi_projection.subgraph(component)
                    fraud_rings.append({
                        "upi_ids": list(component),
                        "size": len(component),
                        "internal_edges": sub.number_of_edges(),
                    })
            fraud_rings.sort(key=lambda x: x["size"], reverse=True)
        except Exception:
            fraud_rings = []
    else:
        fraud_rings = []

    _anomaly_cache = {
        "multi_merchant_upis": multi_merchant_upis,
        "multi_upi_merchants": multi_upi_merchants,
        "suspicious_clusters": suspicious_clusters,
        "high_betweenness_nodes": high_betweenness,
        "fraud_rings": fraud_rings[:5],
        "graph_stats": {
            "total_nodes": G.number_of_nodes(),
            "total_edges": G.number_of_edges(),
            "upi_nodes": len(upi_nodes),
            "merchant_nodes": len(merchant_nodes),
            "connected_components": nx.number_connected_components(G),
        },
    }

    return _anomaly_cache


def get_upi_risk_from_graph(upi_id: str) -> dict:
    """
    Get graph-based risk assessment for a specific UPI ID.

    Returns:
        {
            "is_anomalous": bool,
            "anomaly_signals": [{"signal": str, "severity": "high"|"medium"|"low", "detail": str}],
            "graph_score_modifier": int  (negative = riskier, applied to base score)
        }
    """
    G = build_graph()
    anomalies = detect_anomalies()

    signals = []
    score_modifier = 0

    if not G.has_node(upi_id):
        return {
            "is_anomalous": False,
            "anomaly_signals": [],
            "graph_score_modifier": 0,
        }

    neighbors = list(G.neighbors(upi_id))

    # Check: UPI linked to multiple merchants
    if len(neighbors) >= UPI_MULTI_MERCHANT_THRESHOLD:
        severity = "high" if len(neighbors) >= 5 else "medium"
        signals.append({
            "signal": "multi_merchant_link",
            "severity": severity,
            "detail": f"This UPI ID is linked to {len(neighbors)} different merchants — possible QR-jacking or money mule pattern.",
        })
        score_modifier -= 20 if severity == "high" else -15

    # Check: Is this UPI part of a fraud ring?
    for ring in anomalies.get("fraud_rings", []):
        if upi_id in ring["upi_ids"]:
            signals.append({
                "signal": "fraud_ring_member",
                "severity": "high",
                "detail": f"This UPI is part of a connected cluster of {ring['size']} UPI IDs sharing merchants — coordinated fraud pattern.",
            })
            score_modifier -= 25
            break

    # Check: High betweenness (bridge node)
    for node_info in anomalies.get("high_betweenness_nodes", []):
        if node_info["node"] == upi_id:
            signals.append({
                "signal": "network_bridge",
                "severity": "medium",
                "detail": f"This UPI acts as a bridge connecting otherwise separate merchant groups (betweenness: {node_info['betweenness']}).",
            })
            score_modifier -= 10
            break

    # Check: Connected to suspicious merchants (those with many UPIs)
    for merchant_id in neighbors:
        for multi in anomalies.get("multi_upi_merchants", []):
            if multi["merchant_id"] == merchant_id:
                signals.append({
                    "signal": "linked_to_multi_upi_merchant",
                    "severity": "low",
                    "detail": f"Connected to merchant '{multi['merchant_name']}' which has {multi['upi_count']} UPI IDs — possible fake storefront.",
                })
                score_modifier -= 5
                break
        if signals and signals[-1]["signal"] == "linked_to_multi_upi_merchant":
            break

    return {
        "is_anomalous": len(signals) > 0,
        "anomaly_signals": signals,
        "graph_score_modifier": max(-40, score_modifier),  # Cap penalty at -40
    }


def invalidate_cache():
    """Clear caches when data changes (e.g., new reports filed)."""
    global _graph_cache, _anomaly_cache
    _graph_cache = None
    _anomaly_cache = None
