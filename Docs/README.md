First step: 

Creating a provider file so terraform can use k8s
<img width="926" height="874" alt="image" src="https://github.com/user-attachments/assets/078fb956-926f-401d-9b20-489b89e8fdf4" />
This is how it should look once terraform has been initiated. 

Then, confirm with terraform plan:
<img width="923" height="703" alt="image" src="https://github.com/user-attachments/assets/b9eb11d4-ee43-4990-9794-6abe87042347" />

And finally, apply:

<img width="815" height="824" alt="image" src="https://github.com/user-attachments/assets/1b04ccc6-2932-42f9-8c5d-980fd731a2f7" />

Then add helm as a provider and apply. 

<img width="1058" height="309" alt="image" src="https://github.com/user-attachments/assets/18d3618e-bc76-4335-969d-b4dffa0fe8dd" />

Both Kubernetes and Helm must be visible on the provider list. The configuration file will be found in: Terraform/required_providers.tf



