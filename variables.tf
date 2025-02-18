variable "PROJECT_ID" {
    description = "gcp project ID"
    type = string
    default = "harshini-450807"
}

variable "GKE_REGION"{
    description = "default region where resources will be created"
    type = string
    default = "us-central1"
}

variable "GKE_CLUSTER"{
    description = "name of GKE cluster"
    type = string
    default = "usecase-1-cluster"
}

variable "MACHINE_TYPE" {
    description = "machine type for nodes of cluster"
    type = string
    default = "e2-medium"
}

variable "NODE_COUNT"{
    description = "number of nodes"
    type = number
    default = 1
}