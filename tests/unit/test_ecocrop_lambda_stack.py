import json
import pytest

from aws_cdk import core
from ecocrop_lambda.ecocrop_lambda_stack import EcocropLambdaStack


def get_template():
    app = core.App()
    EcocropLambdaStack(app, "ecocrop-lambda")
    return json.dumps(app.synth().get_stack("ecocrop-lambda").template)


def test_sqs_queue_created():
    assert("AWS::SQS::Queue" in get_template())


def test_sns_topic_created():
    assert("AWS::SNS::Topic" in get_template())
