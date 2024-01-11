## Coding Challenge for the New Cloud Capabilities Team (NCC) at Mars Inc.

### Introduction
We are a platform team that manages and provides private networking services for other teams. We are directly responsible for provisioning networking configurations for use by hundreds of developers within Mars. Due to the size of our customer base, it is integral that we use Terraform to deploy Infrastructure as code. Our code base is structured in a way that is as scalable as possible, as reflected in the starter code. 

This coding challenge is meant to assess the following skill sets:
1. Ability to contribute to an existing code base.
2. Ability to write terraform code 
3. Understanding of CI/CD frameworks

**The intended length of this challenge is 4 (four) hours.**

### Code Structure 
The terraform code provided is structured to intake a json input and convert it to terraform code. This allows the platform to specify objects in JSON, which the terraform code then loops through and creates the necessary objects. This json object is written in `variable.auto.tfvars.json`. The starter code creates a resource group, a virtual network, a route table and a private dns zone. These are all specified in the `variable.auto.tfvars.json` file. Adding an additional subnet within the virtual network would involve changing the json file, not going into the module and adding the resource block. 

The terraform modules are housed under the `modules` folder. These are broken out by azure service. A quick look at the `resource_group.tf` reveals the structure of all modules. The module intakes the json object in the `locals` block and then loops over the object in the resource block to create all specified resources. 

This code is executable. If you have terraform installed and an Azure subscription available, under the `CODING_CHALLENGE` folder, you are able to run `terraform init` and `terraform plan`. This is intended and should assist with testing implementation but is not strictly necessary.

### Challenge 
The challenge is the following tasks:

1. Create an additional subnet called `vmsnet-001` within `codingchalleus2vnet` with 32 ip addresses (there will likely be only 27 available). The subnet is meant to house private endpoints associated with Azure Virtual Machines. Please associate the the provided User Defined Route table to the subnet. Difficulty: ★

2. The following codebase creates one virtual network with one firewall. A requirement has come through to scale the network to 50 virtual networks in 6 distinct Azure regions.

    What about the codebase scales well? What doesnt scale well and limits flexibility? 
    
    How would you structure the codebase to enable CI/CD pipelines to be added and run in a managable configuration?

    Does the requirement for multiple Azure regions affect the way you structure the codebase?

    **Note: this challenge does not involve any coding changes, more a discussion around the positives and negatives about structuring the code base in this manner.** Difficulty: ★★

3. As an next step, three central Azure Key Vaults need to be added to the Virtual Network in the solution. The three keyvaults need to be added to the existing subnet `akvpesnet-001`. These Key Vaults must be closed to the public internet and have private endpoints in the vnet. Please complete the terraform needed in the `central_akv.tf` module along with adding to the json objects in the `variable.auto.tfvars.json`. There are TODO flags in both files to help. Difficulty: ★★★

### Challenge Hints:

#### Create an additional subnet

This can be done without touching the terraform modules, the changes should be done in the `variable.auto.tfvars.json` file.

#### Scale the Network



#### Outbound Connectivity through the Firewall

One keyvault has already been specified in the `variable.auto.tfvars.json` file, the additional two akvs should be very similar.

The private endpoint and DNS integration has been completed already, there should be no changes to this aspect of the terraform code. 

The Key Vault should have a default deny network rule for public traffic. Other attributes of the keyvault are not important for this challenge.

It is recommended to use an [output block](https://developer.hashicorp.com/terraform/language/values/outputs) to determine how the local list is structured and edited. Terraform's error messages are not particularly helpful.