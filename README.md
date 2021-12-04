# iac-exercises
A series of IaC exercises

# Structure
Use the attached folder structure to try your hand at implementing the index using the relevant toolset

# Index
1. Single VPC standup
1. Hub VPC standup
1. Spoke VPC standup
1. Hub and spoke VPC standup
1. Build account management structure - management account, billing account, etc
1. Set up a region from template
1. Build a DMZ VPC
1. Build a shared services VPC - backup, logging and monitoring etc
1. Do x for all instances tagged as y
1. Do x for all instances running application y
1. Outbound firewall rules
1. Split horizon DNS/conditional DNS forwarder
1. Tag all entities missing defaults (Default AWS / Cloud Configurations / Default Security Groups / Default Installed Apps)
    1. Ensure that all entities created within a Cloud tenant have the following tag: `iac : <yourname>`
    2. Ensure that all entities within a specified vpc have the following Security Group created and attached
        ``` NAME: iac-sec-pol
           INBOUND: ALLOW: HTTP/80, SSH/22
        ```
    3. Ensure the following applications are installed on all instances running in a VPC:
        - git
        - net-tools
        - wget
        - tcpdump
        - python3
        - firewalld
        - make
        - curl
        - lsof
