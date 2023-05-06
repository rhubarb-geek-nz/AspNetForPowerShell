# Copyright (c) 2023 Roger Brown.
# Licensed under the MIT License.

$Response=$Context.Response
$Response.StatusCode=200
$Response.ContentType='text/plain'
'Hello World'
