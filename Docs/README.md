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

Then, add the helm repos we will be needing for each tool we wish to deploy, and create a namespace on k8s cluster: 

<img width="967" height="105" alt="image" src="https://github.com/user-attachments/assets/7ff3fbf0-38b7-4d6b-96f3-86e463f941c5" />

Here Prometheus and all other monitoring tools will be added into the monitoring namespace: 

<img width="585" height="123" alt="image" src="https://github.com/user-attachments/assets/841dcc47-e909-4c9a-a92f-162c9e0ef98b" />

Then with the following command, prometheus will be installed inside the namespace monitoring and will be deployed: <helm install prometheus prometheus-community/prometheus --namespace monitoring/>

<img width="1394" height="703" alt="image" src="https://github.com/user-attachments/assets/40a44702-b4ea-4c04-8533-a1d1f83971d4" />

Then using: <kubectl get pods -n monitoring /> we can check that the pods are running: 


<img width="885" height="212" alt="image" src="https://github.com/user-attachments/assets/6280a8df-5db7-4ee2-87b8-1e910eebdb74" />

*Note: If you are connected to the corporate network at the office or using a corporate vpn, the state metrics image might not pull. 
