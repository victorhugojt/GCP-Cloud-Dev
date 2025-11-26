Cloud Load Balancer (layer 7-8) App LB Network LB

Proxies-DNS-CDN

Networks Types


VPN -> Cloud VPN to create a “tunnel” connection. - Cloud Router can be used - Cloud Router lets other networks and Google VPC, exchange route information over the VPN using the Border Gateway Protocol - if you add a new subnet to your Google VPC, your on-premises network will automatically get routes to it.

Peering -> Means putting a router in the same public data center as a Google point of presence and using it to exchange traffic between networks (Google has more than 100 points of presence around the world).

Carrier Peering -> gives you direct access from your on-premises network through a service provider's network to Google (Is that it isn’t covered by a Google Service Level Agreement)

Dedicated Interconnect -> If getting the highest uptimes for interconnection is important - This option allows for one or more direct, private connections to Google - if these connections have topologies that meet Google’s specifications, they can be covered by an SLA of up to 99.99% - hese connections can be backed up by a VPN for even greater reliability.

Partner Interconnect -> rovides connectivity between an on-premises network and a VPC network through a supported service provider - useful if a data center is in a physical location that can't reach or if the data needs don’t warrant an entire 10 GigaBytes per second connection -  if these connections have topologies that meet Google’s specifications, they can be covered by an SLA of up to 99.99 - Google isn’t responsible for any aspects of Partner Interconnect provided by the third-party service provider.

Cross-Cloud Interconnect -> helps you establish high-bandwidth dedicated connectivity between Google Cloud and another cloud service provider - Google provisions a dedicated physical connection between the Google network and that of another cloud service provider - You can use this connection to peer your Google Virtual Private Cloud network with your network that's hosted by a supported cloud service provider - supports your adoption of an integrated multicloud strategy . available in two sizes: 10 Gbps or 100 Gbps.