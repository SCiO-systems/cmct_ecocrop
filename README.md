# ECOCROP AWS Lambda Function





## R Documentation

- [CRAN ECOCROP](https://cran.r-project.org/web/packages/Recocrop/index.html)
- [ECOCROP Reference Manual](https://cran.r-project.org/web/packages/Recocrop/Recocrop.pdf)

## Input JSON

The input JSON consists of 4 fields:

1. "work_on_tif" : A boolean vaule (True/False) which indicates if the Lambda function will operate on tif data or not.
2. "model_data" : A list of the parameters for the function *ecocrop()*. Refer to the documentation as to which are these parameters and what are the values to be assigned. In the input JSON example below all the parameters can be seen with dummy values from the R documentation.
3. "run_extra_stats_params" : A list of boolean values indicating the desired output of the ecocrop model run. Refer to the documentation as to what output is produced from each one of the enabled parameters. 
4. "tif_data" : (Optional if "work_on_tif" is *False*) A list of the tif data. Each element of the list contains the url to the tif file and the name of the variable represented by the tif. Refer to R documentation about the specific naming of the variables as it must be strictly selected for the model to run correctly.

Example of input JSON:

~~~json
{
  "work_on_tif": false,
  "model_data": {
    "plant": "maize",
    "add_parameters": [
      {
        "data": [
          0,
          0,
          10,
          30
        ],
        "param_name": "clay"
      }
    ],
    "static_predictors": [
      {
        "data": [
          12
        ],
        "pred_name": "clay"
      }
    ],
    "dynamic_predictors": [
      {
        "data": [
          10,
          12,
          14,
          16,
          18,
          20,
          22,
          20,
          18,
          16,
          14,
          12
        ],
        "pred_name": "tavg"
      },
      {
        "data": [
          50,
          62,
          74,
          86,
          98,
          110,
          122,
          134,
          146,
          158,
          170,
          182
        ],
        "pred_name": "prec"
      }
    ]
  },
  "run_extra_stats_params": {
      "get_max": false,
      "which_max": false,
      "count_max": false,
      "lim_fact": false
  },
  "tif_data": [
    {
      "tif_path": "https://r-lambdas-dummy.s3.eu-central-1.amazonaws.com/ta.tif",
      "tif_variable_name": "tavg"
    },
    {
      "tif_path": "https://r-lambdas-dummy.s3.eu-central-1.amazonaws.com/pr.tif",
      "tif_variable_name": "prec"
    },
    {
      "tif_path": "https://r-lambdas-dummy.s3.eu-central-1.amazonaws.com/ph.tif",
      "tif_variable_name": "ph"
    }
    
  ]
}
~~~

## Using the Lambda Function in R

The proper way to use the Lambda function through an R script is shown below:

~~~R
# required libraries
library("httr")
library("jsonlite")

## 1st way to send data, with a URL of the json file
post_input_json = "https://r-lambdas-dummy.s3.eu-central-1.amazonaws.com/ecocrop_parameters.json"

## 2nd way to send data, loading from local json file and converting it to the appropriate format for the POST call
input_local_file_path = "ecocrop_parameters.json" #provide the correct path to JSON
input_json = fromJSON(input_local_file_path)
post_input_json = toJSON(input_json)

## create the headers for the POST call
header = add_headers(.headers = c('Authorization'= 'sc10_lambda_auth', 'Content-Type' = 'application/json'))
## execute the POST call
response = POST(url = "https://lambda.ecocrop.scio.services", config = header , body = post_input_json)

## get the returned data as a R list
data_list = content(response)
## get the returned data as a json variable (can be saved as local json file)
data_json = toJSON(data_list)

~~~

## Output

There are two possible formats of the output of this Lambda function, depending on the "*work_on_tif*" option of the input json. 

1. If  "*work_on_tif*" is **False** then the response of a successful run of the lambda function should look like the examples below. More specifically, the response is containing the result of the ECOCROP *ecocrop_model run()*. In detail, the function's output is a R list which is converted to a JSON.
   The following output is produced with setting **all** of the *"run_extra_stats_params"* as **False**.

   ~~~json
   [
     {
       "day": [
         "day-1"
       ],
       "month": [
         "Jan"
       ],
       "value": [
         0
       ]
     },
     {
       "day": [
         "day-15"
       ],
       "month": [
         "Jan"
       ],
       "value": [
         0
       ]
     },
     {
       "day": [
         "day-1"
       ],
       "month": [
         "Feb"
       ],
       "value": [
         0.1
       ]
     },
     {
       "day": [
         "day-15"
       ],
       "month": [
         "Feb"
       ],
       "value": [
         0.2
       ]
     }
     ...
   ]
   ~~~

   The following output is produced with setting **at least** of the *"run_extra_stats_params"*  as **True**. Refer to the documentation as to what result is produced from the enabled parameter(s). More specifically, from the "*run_extra_stats_params*", the parameter "*get_max*" was set as **True**.

   ~~~json
   [
       {
           "get_max":[0.9]
       }
   ] 
   ~~~

   In the section "Using the Lambda Function in R" , it is shown how to obtain the output as a R list or as a JSON.
   
2. If  "*work_on_tif*" is **True** then the response of a successful run of the lambda function should look like the examples below. More specifically, the output of the function is a tif file, so the response is containing the **url** of the ECOCROP *ecocrop_model predict()* output tif. The file is given an ID and is followed by the time the creation took place. The file can be downloaded and use appropriately from the user.

   ~~~json
   [
     [
       "https://lambda-ecocrop.s3.eu-central-1.amazonaws.com/ecocrop_result_EKSWS0930U_2021_11_09_14_20_53.tif"
     ]
   ]
   ~~~

   





## Deployment

![](https://scio-images.s3.us-east-2.amazonaws.com/ecocrop.png)

### Prerequistes

- AWS Account
- AWS CLI
- Node.js
- Python
- AWS CDK Toolkit
- Docker

The AWS services that are being used are the the ones below:

- CloudFormation
- Lambda
- Elastic Container Registry
- API Gateway
- S3

Those are being combined by utilizing AWS Cloud Development Kit (CDK), a software development framework for defining cloud infrastructure in code and provisioning it through AWS CloudFormation.

You can read more about AWS CDK in its official documentation page and you can also the below relevant workshop to get you started.

[What is the AWS CDK?](https://docs.aws.amazon.com/cdk/latest/guide/home.html)

[AWS CDK Workshop](https://cdkworkshop.com/)



We are using Python as our code hence all the workflow will be demonstrated with it. 

The steps are not different if you are using any other language that the toolkit supports although relevant debugging will be needed from the code's perspective.

First, you will need to generate AWS access keys. Make sure that the user account that will be used has IAM permissions for access to the resources and services mentioned.

Once you have generated the keys, you may install AWS CLI and add them to your machine.

You can read more in the official documentation for its installation and configuration.

[AWS Command Line Interface documentation](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html)



Since the architecture of this function includes integration with S3, you will have to manually create a bucket and also make sure that the AWS access keys that will be used will have access to it.



Once you have this set up, you may proceed with the below steps.

```bash
# Installation of CDK toolkit
npm install -g aws-cdk@1.85.0

# Confirm successful installation of CDK
cdk version 

# Creating virtual environemnt for Python
python3 -m venv .venv 

# Activating the virtual environment for CDK
source .venv/bin/activate 

# Installing Python CDK dependencies 
pip3 install -r requirements.txt 
```



You will now need to add your AWS access keys to the Dockerfile in order for the container to have access to the defined S3 bucket.

```dockerfile
RUN aws configure set aws_access_key_id <<Access key ID>>
RUN aws configure set aws_secret_access_key <<Secret access key>>
```



Now you can deploy by using CDK.

```bash
# Getting AWS account information for CDK
ACCOUNT_ID=$(aws sts get-caller-identity --query Account | tr -d '"')
AWS_REGION=$(aws configure get region)

# Deploying
cdk bootstrap aws://${ACCOUNT_ID}/${AWS_REGION}
cdk deploy --require-approval never
```

With `cdk bootstrap` command, a CloudFormation stack is creating based on the `app.py`.  

Then with `cdk deploy` the resources of the CloudFormation stack are being created and deployed. This process will take time as the container is being built and the completion is depending  and in the internal operations of the container (installing and running the needed dependencies as those are defined in the Dockerfile) and on the resources of the host machine.

Afterwards, the container will be pushed to AWS ECR (Elastic Container Registry) which is the container registry service of AWS. This will take some time as well as it depends on the internet connection you have.



Once the above complete, you may navigate to API Gateway service from the AWS console and you will find the API with the name "wofost-lambda". The name of the API, lambda function & container is being set in the *app.py* (line 13).

You will then see URL that has been created in the form of:

 `https://<random text>.execute-api.<your aws region>.amazonaws.com`

The lambda function is now ready to be used! 

Fore more detailed information about the ecosystem, you may check [this article](https://medium.com/swlh/deploying-a-serverless-r-inference-service-using-aws-lambda-amazon-api-gateway-and-the-aws-cdk-65db916ea02c).

