"""An AWS Python Pulumi program"""

import pulumi
import pulumi_aws as aws


tags = {
    "project": "IaC-exercises",
    "exercise": "Pulumi-3-on_prem_vpn_to_transit_vpc",
}

# get external resources
home_ip = aws.ssm.get_parameter(name="home_ip")

# ubuntu = aws.ec2.get_ami_ids(
#    filters=[
#        aws.ec2.GetAmiIdsFilterArgs(
#            name="name",
#            values=["ubuntu/images/ubuntu-*-*-amd64-server-*"],
#        )
#    ],
#    owners=["099720109477"],
# )


ubuntu = aws.ec2.get_ami(
    filters=[
        aws.ec2.GetAmiFilterArgs(
            name="name",
            values=["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"],
        ),
        aws.ec2.GetAmiFilterArgs(
            name="root-device-type",
            values=["ebs"],
        ),
        aws.ec2.GetAmiFilterArgs(
            name="virtualization-type",
            values=["hvm"],
        ),
    ],
    most_recent=True,
    owners=["099720109477"],
)


### Begin with client site
# start instantiating stuff
# start with a vpc
client_vpc = aws.ec2.Vpc(
    "client_site",
    cidr_block="192.168.0.0/16",
    tags=tags,
)

# then a subnet
client_subnet = aws.ec2.Subnet(
    "client_site_subnet",
    vpc_id=client_vpc.id,
    cidr_block="192.168.0.0/24",
    tags=tags,
)

# then add in a igw
gw = aws.ec2.InternetGateway("gw", vpc_id=client_vpc.id, tags=tags)

# set up routing to the igw
route_default_to_igw = aws.ec2.Route(
    "route_default_to_igw",
    route_table_id=client_vpc.main_route_table_id,
    destination_cidr_block="0.0.0.0/0",
    gateway_id=gw.id,
)

# create an sg
security_group_client_site = aws.ec2.SecurityGroup(
    "securityGroupClientSite",
    description="All of the rules to allow the VPN instance to work",
    vpc_id=client_vpc.id,
    tags=tags,
)

# and add rules to it
sgr_ingress_ssh = aws.ec2.SecurityGroupRule(
    "inbound-ssh",
    type="ingress",
    from_port=22,
    to_port=22,
    protocol="tcp",
    cidr_blocks=[home_ip.value],
    security_group_id=security_group_client_site.id,
)

sgr_ingress_cloud_site = aws.ec2.SecurityGroupRule(
    "inbound-cloud-site",
    type="ingress",
    from_port=0,
    to_port=0,
    protocol="-1",
    cidr_blocks=["10.0.0.0/16"],
    security_group_id=security_group_client_site.id,
)

sgr_egress = aws.ec2.SecurityGroupRule(
    "outbound-any",
    type="egress",
    from_port=0,
    to_port=0,
    protocol="-1",
    cidr_blocks=["0.0.0.0/0"],
    security_group_id=security_group_client_site.id,
)

# instantiate the ec2 instance that will act as the vpn endpoint
vpn_instance = aws.ec2.Instance(
    "vpn_instance",
    ami=ubuntu.id,
    instance_type="t3.micro",
    key_name="chris-syd",
    subnet_id=client_subnet.id,
    vpc_security_group_ids=[security_group_client_site.id],
    tags=tags,
)

# the ec2 instance needs an EIP so that its public IP does not change
instance_endpoint = aws.ec2.Eip(
    "ec2-instance-vpn-endpoint",
    instance=vpn_instance.id,
    vpc=True,
    tags={**tags, **{"vpn-gw": "true"}},
)


# make the cloud site

# get the eip attached to the ec2 instance
# just because I want to, instead of referring to it via the variable instance_endpoint.id, look it up using tags
eip_handle = aws.ec2.get_elastic_ip(tags={"vpn-gw": "true"})

print(f"EIP is {eip_handle.public_ip}")

# start with a vpc
cloud_vpc = aws.ec2.Vpc(
    "cloud_site",
    cidr_block="10.0.0.0/16",
    tags=tags,
)

# then a subnet
cloud_subnet = aws.ec2.Subnet(
    "cloud_site_subnet",
    vpc_id=cloud_vpc.id,
    cidr_block="10.0.0.0/24",
    tags=tags,
)

# then add in a igw
cloud_igw = aws.ec2.InternetGateway("cloud_igw", vpc_id=cloud_vpc.id, tags=tags)

# set up routing to the igw
route_default_to_igw = aws.ec2.Route(
    "cloud_route_default_to_igw",
    route_table_id=cloud_vpc.main_route_table_id,
    destination_cidr_block="0.0.0.0/0",
    gateway_id=cloud_igw,
)

# create an sg
security_group_cloud_site = aws.ec2.SecurityGroup(
    "securityGroupCloudSite",
    description="All of the rules to allow the VPN instance to work",
    vpc_id=cloud_vpc.id,
    tags=tags,
)

# and add rules to it
sgr_ingress_ssh = aws.ec2.SecurityGroupRule(
    "cloud_inbound-ssh",
    type="ingress",
    from_port=22,
    to_port=22,
    protocol="tcp",
    cidr_blocks=[home_ip.value],
    security_group_id=security_group_cloud_site.id,
)

sgr_ingress_cloud_site = aws.ec2.SecurityGroupRule(
    "cloud_inbound-cloud-site",
    type="ingress",
    from_port=0,
    to_port=0,
    protocol="-1",
    cidr_blocks=["192.168.0.0/16"],
    security_group_id=security_group_cloud_site.id,
)

sgr_egress = aws.ec2.SecurityGroupRule(
    "cloud_outbound-any",
    type="egress",
    from_port=0,
    to_port=0,
    protocol="-1",
    cidr_blocks=["0.0.0.0/0"],
    security_group_id=security_group_cloud_site.id,
)

# customer gateway
cloud_customer_gateway = aws.ec2.CustomerGateway(
    "customer-gateway",
    bgp_asn="65000",
    ip_address=eip_handle.public_ip,
    tags=tags,
    type="ipsec.1",
)

cloud_transit_gw = aws.ec2transitgateway.TransitGateway(
    "transit-gw",
    description="cloud transit gw",
    dns_support="enable",
    vpn_ecmp_support="enable",
    default_route_table_association="enable",
    default_route_table_propagation="enable",
)

cloud_transit_gw_vpc_attachment = aws.ec2transitgateway.VpcAttachment(
    "tgw to vpc attachment",
    subnet_ids=[cloud_subnet.id],
    transit_gateway_id=cloud_transit_gw.id,
    vpc_id=cloud_vpc.id,
)


## has the same issue at TF - the tgw reports its complete but its not yet ready to accept changes like adding routes to it, eg:
#  aws:ec2:Route (client_site_via_tgw):
#    error: 1 error occurred:
#        * error creating Route in Route Table (rtb-0be7e92f0a1872d7e) with destination (192.168.0.0/16): InvalidGatewayID.NotFound: The gateway ID 'tgw-0db10e42f003616aa' does not exist
#        status code: 400, request id: 15741046-3e47-41da-a130-caf9ce06befd
#
# Pulumi doesn't have a sleep function like TF does, so pulumi up needs to be re-run,
# or you could always just do time.sleep(60)
# or you could use boto3/raw AWS API query to check the tgw's lifecycle state
#
# TF suffers from the same issue as Pulumi, which makes it even clearer to me that Pulumi is just a wrapper for TF (and maybe some other providers)

# set up from the cloud vpc to the client cidr ranges via the tgw
route_client_cidr_via_tgw = aws.ec2.Route(
    "client_site_via_tgw",
    route_table_id=cloud_vpc.main_route_table_id,
    destination_cidr_block="192.168.0.0/16",
    gateway_id=cloud_transit_gw.id,
)
