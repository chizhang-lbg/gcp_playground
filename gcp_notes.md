# Setup 
## For using GitHub repository: EricRen-LBG
1. Create ssh keys for using github   
$ ssh-keygen -t ed25519 -C "Chi-Charles.Zhang@lloydsbanking.dev"

2. Start the ssh agent and add the newly generated key   
$ eval "$(ssh-agent -s)"   
$ ssh-add ~/.ssh/id_ed25519 


3. Upload the ssh public key to github
Github: Settings --> SSH and GPg keys --> New SSH key

## For using git
$ git config --global user.name "Chi Zhang"
$ git config --global user.email "chi-charles.zhang@lloydsbanking.com"

# git lol to show branch history
$ git config --global alias.lol "log --graph --decorate --pretty=oneline --abbrev-commit --all"

To check all setting:   
$ git config --list


# == Load csv to BigQuery ==
BigQuery Studio > Add > Load file


# == Load BigQuery table from notebook ==
> option 1: in the notebook cell
%%bigquery churn_rawdata
SELECT 
  *
FROM 
  playpen-d5de31.data_science_dataset.churn_data;

> option 2: in the notebook cell
from google.cloud import bigquery
client = bigquery.Client()

sql = """
SELECT *
FROM playpen-d5de31.data_science_dataset.churn_data;
"""
my_dataframe_name = client.query(sql).to_dataframe()


# === Vertex Pipelines (Kubeflow pipeline)===

** Task 1: Vertex Pipelines setup
[Step 1: Create Python notebook and install libraries]
> create a new notebook instance at Vertex AI, then open JupyterLab

> create a new python notebook

> To install both services needed for this lab, first set the user flag in a notebook cell:
USER_FLAG = "--user"

> Then run the following from your notebook:
!pip3 install {USER_FLAG} google-cloud-aiplatform==1.0.0 --upgrade
!pip3 install {USER_FLAG} kfp google-cloud-pipeline-components==0.1.1 --upgrade

> After installing these packages you'll need to restart the kernel:
import os

if not os.getenv("IS_TESTING"):
    # Automatically restart kernel after installs
    import IPython

    app = IPython.Application.instance()
    app.kernel.do_shutdown(True)
    
> Finally, check that you have correctly installed the packages. The KFP SDK version should be >=1.6:
!python3 -c "import kfp; print('KFP SDK version: {}'.format(kfp.__version__))"
!python3 -c "import google_cloud_pipeline_components; print('google_cloud_pipeline_components version: {}'.format(google_cloud_pipeline_components.__version__))"

[Step 2: Set your project ID and bucket]
> If you don't know your project ID you may be able to get it by running the following:
import os
PROJECT_ID = ""
# Get your Google Cloud project ID from gcloud
if not os.getenv("IS_TESTING"):
    shell_output=!gcloud config list --format 'value(core.project)' 2>/dev/null
    PROJECT_ID = shell_output[0]
    print("Project ID: ", PROJECT_ID)

> Then create a variable to store your bucket name
BUCKET_NAME="gs://" + PROJECT_ID + "-bucket"

[Step 3: Import libraries]
> Add the following to import the libraries you'll be using throughout this lab

from typing import NamedTuple

import kfp
from kfp import dsl
from kfp.v2 import compiler
from kfp.v2.dsl import (Artifact, Dataset, Input, InputPath, Model, Output,
                        OutputPath, ClassificationMetrics, Metrics, component)
from kfp.v2.google.client import AIPlatformClient

from google.cloud import aiplatform
from google_cloud_pipeline_components import aiplatform as gcc_aip

[Step 4: Define constants]
The last thing you need to do before building the pipeline is define some constant variables. PIPELINE_ROOT is the Cloud Storage path where the artifacts created by your pipeline will be written. You're using us-west1 as the region here, but if you used a different region when you created your bucket, update the REGION variable in the code below:

PATH=%env PATH
%env PATH={PATH}:/home/jupyter/.local/bin
REGION="us-west1"

PIPELINE_ROOT = f"{BUCKET_NAME}/pipeline_root/"
PIPELINE_ROOT

** Task 2: Creating your pipeline
You'll create a pipeline that prints out a sentence using two outputs: a product name and an emoji description. This pipeline will consist of three components:

- product_name: This component will take a product name as input, and return that string as output.
- emoji: This component will take the text description of an emoji and convert it to an emoji. For example, the text code for ✨ is "sparkles". This component uses an emoji library to show you how to manage external dependencies in your pipeline.
- build_sentence: This final component will consume the output of the previous two to build a sentence that uses the emoji. For example, the resulting output might be "Vertex Pipelines is ✨".

[Step 1: Create a Python function based component]
Using the KFP SDK, you can create components based on Python functions. First build the product_name component, which simply takes a string as input and returns that string. Add the following to your notebook:

@component(base_image="python:3.9", output_component_file="first-component.yaml")
def product_name(text: str) -> str:
    return text


Take a closer look at the syntax here:

The @component decorator compiles this function to a component when the pipeline is run. You'll use this anytime you write a custom component.
The base_image parameter specifies the container image this component will use.
The output_component_file parameter is optional, and specifies the yaml file to write the compiled component to. After running the cell you should see that file written to your notebook instance. If you wanted to share this component with someone, you could send them the generated yaml file and have them load it with the following:

product_name_component = kfp.components.load_component_from_file('./first-component.yaml')


[Step 2: Create two additional components]

1. To complete the pipeline, create two more components. The first one takes a string as input, and converts this string to its corresponding emoji if there is one. It returns a tuple with the input text passed, and the resulting emoji:

@component(base_image="python:3.9", output_component_file="second-component.yaml", packages_to_install=["emoji"])
def emoji(
    text: str,
) -> NamedTuple(
    "Outputs",
    [
        ("emoji_text", str),  # Return parameters
        ("emoji", str),
    ],
):
    import emoji

    emoji_text = text
    emoji_str = emoji.emojize(':' + emoji_text + ':', language='alias')
    print("output one: {}; output_two: {}".format(emoji_text, emoji_str))
    return (emoji_text, emoji_str)
    
This component is a bit more complex than the previous one. Here's what's new:

The packages_to_install parameter tells the component any external library dependencies for this container. In this case, you're using a library called emoji.
This component returns a NamedTuple called Outputs. Notice that each of the strings in this tuple have keys: emoji_text and emoji. You'll use these in your next component to access the output.
