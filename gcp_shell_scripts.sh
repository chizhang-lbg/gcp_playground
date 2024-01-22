# list the active account name 
gcloud auth list

# list the project ID
gcloud config list project

# use gcloud to enable the services used in the lab
gcloud services enable \
  compute.googleapis.com \
  iam.googleapis.com \
  iamcredentials.googleapis.com \
  monitoring.googleapis.com \
  logging.googleapis.com \
  notebooks.googleapis.com \
  aiplatform.googleapis.com \
  bigquery.googleapis.com \
  artifactregistry.googleapis.com \
  cloudbuild.googleapis.com \
  container.googleapis.com
  

#Create Vertex AI custom service account for Vertex Tensorboard integration  
# Create custom service account
SERVICE_ACCOUNT_ID=vertex-custom-training-sa
gcloud iam service-accounts create $SERVICE_ACCOUNT_ID  \
    --description="A custom service account for Vertex custom training with Tensorboard" \
    --display-name="Vertex AI Custom Training"
    
    
# Grant it access to Cloud Storage for writing and retrieving Tensorboard logs
PROJECT_ID=$(gcloud config get-value core/project)
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member=serviceAccount:$SERVICE_ACCOUNT_ID@$PROJECT_ID.iam.gserviceaccount.com \
    --role="roles/storage.admin"
    
    
# Grant it access to your BigQuery data source to read data
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member=serviceAccount:$SERVICE_ACCOUNT_ID@$PROJECT_ID.iam.gserviceaccount.com \
    --role="roles/bigquery.admin"
    
# Grant it access to Vertex AI for running model training, deployment, and explanation jobs:
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member=serviceAccount:$SERVICE_ACCOUNT_ID@$PROJECT_ID.iam.gserviceaccount.com \
    --role="roles/aiplatform.user"
    
# Clone the git repository
git clone https://github.com/GoogleCloudPlatform/training-data-analyst

# Install libraries & dependencies
cd training-data-analyst/self-paced-labs/vertex-ai/vertex-ai-qwikstart
pip3 install --user -r requirements.txt


# -- Create a Cloud Storage bucket --
# set environment variables
export PROJECT_ID=$DEVSHELL_PROJECT_ID
export BUCKET=$PROJECT_ID
# create a Cloud Storage bucket
gsutil mb -p $PROJECT_ID \
    -c standard    \
    -l "REGION" \
    gs://${BUCKET}

# List the buckets in a project
gcloud storage ls

# Copy files into Cloud Storage bucket
gsutil -m cp -r gs://car_damage_lab_images/* gs://${BUCKET}



# create a copy of the file
gsutil cp gs://car_damage_lab_metadata/data.csv .
# update the CSV with the path to your storage
sed -i -e "s/car_damage_lab_images/${BUCKET}/g" ./data.csv
# Verify your bucket name was inserted into the CSV properly
cat ./data.csv
# upload the CSV file to Cloud Storage bucket
gsutil cp ./data.csv gs://${BUCKET}


# Find the project number
# Navigation menu > Cloud Overview > Dashboard.


# Grant editor's role to project service account
1) In the Google Cloud console, on the Navigation menu, click Cloud Overview > Dashboard.
2) Copy the project number (e.g. 729328892908).
3) On the Navigation menu, select IAM & Admin > IAM.
4) At the top of the roles table, below View by Principals, click Grant Access.
5) For New principals, type:
  {project-number}-compute@developer.gserviceaccount.com
6)Replace {project-number} with your project number.
7) For Role, select Project (or Basic) > Editor.
8) Click Save.


# Connect BigQuery data to Cloud Dataprep
On the Cloud Dataprep page:

1) Click Create a new flow.
2) Click Untitled Flow on the top of the page.
3) In the Rename dialog, specify these details:
    - For Flow Name, type Ecommerce Analytics Pipeline
    - For Flow Description, type Revenue reporting table for Apparel
4)Click Ok.
5) Click (+) icon to add a dataset.
6) In the Add datasets to flow dialog, click Import datasets from bottom-left corner.
7) In the left pane, click BigQuery.
8) When your ecommerce dataset is loaded, click on it.
9) To create a dataset, click Create dataset (Create dataset icon).
10) Click Import & Add to Flow.
The data source automatically updates.


# create a new folder
$ mkdir folder_name

# clone a google source repository 
$ gcloud source repos clone devops-repo

# To commit changes to the google repository, you have to identify yourself. Enter the following commands, but with your information (you can just use your Gmail address or any other email address):
$ git config --global user.email "you@example.com"
$ git config --global user.name "Your Name"


# commit the changes locally before pushing to the google repository
$ git commit -a -m "Initial Commit"

# You committed the changes locally, but have not updated the Git repository you created in Cloud Source Repositories. Enter the following command to push your changes to the cloud (google repository):
$ git push origin master


# The Cloud Shell environment variable DEVSHELL_PROJECT_ID automatically has your current project ID stored
$ echo $DEVSHELL_PROJECT_ID


# Enter the following command to create an Artifact Registry repository named devops-repo
$ gcloud artifacts repositories create devops-repo --repository-format=docker --location=us-central1

# To configure Docker to authenticate to the Artifact Registry Docker repository, enter the following command:
$ gcloud auth configure-docker us-central1-docker.pkg.dev

# To use Cloud Build to create the image and store it in Artifact Registry, type the following command:
$ gcloud builds submit --tag us-central1-docker.pkg.dev/$DEVSHELL_PROJECT_ID/devops-repo/devops-image:v0.1 .

us-central1-docker.pkg.dev/qwiklabs-gcp-00-f20d7932c406/devops-repo/devops-image:v0.1
us-central1-docker.pkg.dev/qwiklabs-gcp-00-f20d7932c406/devops-repo/devops-image:$COMMIT_SHA



# # # Automatically restart google notebook kernel after installs
import os
if not os.getenv("IS_TESTING"):
    # Automatically restart kernel after installs
    import IPython
    app = IPython.Application.instance()
    app.kernel.do_shutdown(True)
    
