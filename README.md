Fill in the file "terraform.tfvars" with your environment details. Then run:

`terraform init`

`terraform apply -auto-approve`

This will spin up the VM and install all the packages, libraries, code and configurations needed (it will take some time to complete the process). To confirm the VM is ready to run tests, you can SSH to the VM and do:

`tail -f /var/log/startup-script.log`

Wait until you see the following and no errors:

`✅ Setup complete. Ready to test!`

Then run:

`source ~/.bashrc`
