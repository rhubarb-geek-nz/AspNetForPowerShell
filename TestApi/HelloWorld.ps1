# Copyright (c) 2023 Roger Brown.
# Licensed under the MIT License.

param($context)
$response = $context.Response
$response.StatusCode = 200
$response.ContentType = 'text/plain'
'Hello World'
