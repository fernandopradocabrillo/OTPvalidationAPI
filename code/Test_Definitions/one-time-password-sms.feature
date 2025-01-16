Feature: CAMARA OTPvalidationAPI, v:1.0.0

# Environment variables:
# * api_root: API root of the server URL
# * phone_number: A public identifier (MSISDN) addressing a telephone subscriptionable to receive SMS. Accordingly to E.164 standard, must be prefixed with '+'.
#     *For additional test scenarios, operator could provide phone number for line that cannot receive SMS, line that blocked SMS reception, not belonging to the operator, designing a landline number.
# * message: Message template used to compose the content of the SMS sent to the phone number. It must include the following label indicating where to include the short code {{code}}. Operator could specified a max_lenght for the message.
# * authentication_id: identifier of a a send-code request. Identifier retrieved in send-code response.
# * max_sent: Maximum allowed request to send code for a given device
# * max_try: Maximum allowed try to validate the code for a given autorisation request.
# References to OAS spec schemas refer to schemas specifies in one-time-password-sms.yaml, version wip

Background: Common OTPvalidationAPI setup
    Given an environment at "apiRoot"                                                               |
    And the header "Content-Type" is set to "application/json"
    And the header "Authorization" is set to a valid access token
    And the header "x-correlator" is set to a UUID value
    And the request body is set by default to a request body compliant with the schema

####################################
# Happy path scenarios for send-code
####################################

@OTPvalidationAPI_01_send_code_success_scenario
Scenario: Validation for sucess send-code scenario
    Given the request body property "$.phoneNumber" is set to config_var: "phone_number" or the phoneNumber is identified by the token
    And the request body property "$.message" is set to config_var: "message"
    And the resource "/one-time-password-sms/v1/send-code"
    When the HTTP "POST" request is sent
    Then the response property "$.status" is 200
    And the response header "Content-Type" is "application/json"
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response body complies with the OAS schema at "/components/schemas/SendCodeResponse"

@OTPvalidationAPI_02_send_code_success_scenario_without_x-correlator
Scenario: Validation for sucess send-code scenario without x-correlator
    Given the request body property "$.phoneNumber" is set to config_var: "phone_number" or the phoneNumber is identified by the token
    And the request body property "$.message" is set to config_var: "message"
    And the resource "/one-time-password-sms/v1/send-code"
    And the header "Authorization" is set
    When the HTTP "POST" request is sent
    Then the response property "$.status" is 200
    And the response header "Content-Type" is "application/json"
    And the response body complies with the OAS schema at "/components/schemas/SendCodeResponse"

########################################
# Happy path scenarios for validate-code
########################################

@OTPvalidationAPI_01_validate_code_sucess_scenario
Scenario:  Validation for sucess validate-code scenario
    Given an authenticationId has been retrieved from a send-code request
    And the request body property "$.code" is set to the value received in the SMS
    And the resource "/one-time-password-sms/v1/validate-code"
    When the HTTP "POST" request is sent
    Then the response property "$.status" is 204
    And the response header "x-correlator" has same value as the request header "x-correlator"

@OTPvalidationAPI_02_validate_code_sucess_scenario_without_x-correlator
Scenario:  Validation for sucess validate-code scenario without x-correlator
    Given an authenticationId has been retrieved from a send-code request
    And the request body property "$.code" is set to the value received in the SMS
    And the resource "/one-time-password-sms/v1/validate-code"
    And the header "Authorization" is set
    When the HTTP "POST" request is sent
    Then the response property "$.status" is 204

################################################################################
# Rainy path scenarios for send-code
################################################################################

# Following part describe scenario to test error code defined in the yaml
# These scenarios cover following http status: 400, 401, 403 & 404

# Following error code is not managed in scenarios
# -429 as it could not be easily tested

###########################
#  400 errors for send-code
###########################

@OTPvalidationAPI_400.1_send_code_no_request_body
Scenario: Missing request body for send_code
    Given the request body is not included
    And the resource "/one-time-password-sms/v1/send-code"
    When the HTTP "POST" request is sent
    Then the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" contains a user friendly text
    And the response header "x-correlator" has same value as the request header "x-correlator"

@OTPvalidationAPI_400.2_send_code_empty_request_body
Scenario: Empty object as request body for send_code
    Given the request body is set to "{}"
    And the resource "/one-time-password-sms/v1/send-code"
    When the HTTP "POST" request is sent
    Then the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" contains a user friendly text
    And the response header "x-correlator" has same value as the request header "x-correlator"

@OTPvalidationAPI_400.4_send_code_incorrect_phone_number_request_body
Scenario: Incorrect phone number in the request
    Given the request body property "$.phoneNumber" is set to "3301" and the phoneNumber cannot be identified by the token
    And the request body property "$.message" is set to config_var: "message"
    And the resource "/one-time-password-sms/v1/send-code"
    When the HTTP "POST" request is sent
    Then the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" contains a user friendly text
    And the response header "x-correlator" has same value as the request header "x-correlator"

@OTPvalidationAPI_400.5_send_code_missing_message
Scenario: Missing message request attribute
    Given the request body property "$.phoneNumber" is set to config_var: "phone_number" and the phoneNumber cannot be identified by the token
    And the request body property "$.message" is not valued
    And the resource "/one-time-password-sms/v1/send-code"
    When the HTTP "POST" request is sent
    Then the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" contains a user friendly text
    And the response header "x-correlator" has same value as the request header "x-correlator"

@OTPvalidationAPI_400.6_send_code_missing_code_request_body
Scenario: Missing {{code}} in message request attribute
    Given the request body property "$.phoneNumber" is set to config_var: "phone_number" and the phoneNumber cannot be identified by the token
    And the request body property "$.message" is set to "message without code"
    And the resource "/one-time-password-sms/v1/send-code"
    When the HTTP "POST" request is sent
    Then the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" contains a user friendly text
    And the response header "x-correlator" has same value as the request header "x-correlator"

@OTPvalidationAPI_400.7_send_code_message_too_long
Scenario: message attribute exceed maximum lenght authorized
    Given the request body property "$.phoneNumber" is set to config_var: "phone_number" and the phoneNumber cannot be identified by the token
    And the request body property "$.message" is longer than config_var:"max_lenght"
    And the resource "/one-time-password-sms/v1/send-code"
    When the HTTP "POST" request is sent
    Then the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" contains a user friendly text
    And the response header "x-correlator" has same value as the request header "x-correlator"

###########################
#  401 errors for send-code
###########################

@OTPvalidationAPI_401.1_send_code_no_authorization_header
Scenario: No Authorization header for send-code
    Given the header "Authorization" is removed
    And the resource "/one-time-password-sms/v1/send-code"
    When the HTTP "POST" request is sent
    Then the response property "$.status" is 401
    And the response property "$.code" is "UNAUTHENTICATED"
    And the response property "$.message" contains a user friendly text
    And the response header "x-correlator" has same value as the request header "x-correlator"

@OTPvalidationAPI_401.2_send_code_expired_access_token
Scenario: Expired access token for send-code
    Given the header "Authorization" is set to an expired access token
    And the resource "/one-time-password-sms/v1/send-code"
    When the HTTP "POST" request is sent
    Then  the response property "$.status" is 401
    And the response property "$.code" is "UNAUTHENTICATED"
    And the response property "$.message" contains a user friendly text
    And the response header "x-correlator" has same value as the request header "x-correlator"

@OTPvalidationAPI_401.3_send_code_invalid_access_token
Scenario: Invalid access token for send-code
    Given the header "Authorization" is set to an invalid access token
    And the resource "/one-time-password-sms/v1/send-code"
    When the HTTP "POST" request is sent
    Then the response property "$.status" is 401
    And the response property "$.code" is "UNAUTHENTICATED"
    And the response property "$.message" contains a user friendly text
    And the response header "x-correlator" has same value as the request header "x-correlator"

###########################
#  403 errors for send-code
###########################

@OTPvalidationAPI_03_send_code_max_otp_code
Scenario: Validation for failed scenario too many codes have been requested
    Given the request body property "$.phoneNumber" is set to config_var: "phone_number"
    And the phoneNumber cannot be identified by the token
    And the request body property "$.message" is set to config_var: "message"
    And the resource "/one-time-password-sms/v1/send-code"
    And (config_var:"max_send"-1) of send-code requests for this phone number has been submitted
    When the HTTP "POST" request is sent
    Then the response property "$.status" is 403
    And the response property "$.code" is "ONE_TIME_PASSWORD_SMS.MAX_OTP_CODES_EXCEEDED"
    And the response property "$.message" contains a user friendly text
    And the response header "x-correlator" has same value as the request header "x-correlator"

@OTPvalidationAPI_04_send_code_phone_number_not_allowed
Scenario: Validation for failed scenario for a phone number that cannot receive SMS
    Given the request body property "$.phoneNumber" is set to a phone number that cannot receive SMS
    And the phoneNumber cannot be identified by the token
    And the request body property "$.message" is set to config_var: "message"
    And the resource "/one-time-password-sms/v1/send-code"
    When the HTTP "POST" request is sent
    Then the response property "$.status" is 403
    And the response property "$.code" is "ONE_TIME_PASSWORD_SMS.PHONE_NUMBER_NOT_ALLOWED"
    And the response property "$.message" contains a user friendly text
    And the response header "x-correlator" has same value as the request header "x-correlator"

@OTPvalidationAPI_05_send_code_phone_number_not_allowed_3
Scenario: Validation for failed scenario for a phone number that target a landline
    Given the request body property "$.phoneNumber" is set to a phone number that target a landline
    And the phoneNumber cannot be identified by the token
    And the request body property "$.message" is set to config_var: "message"
    And the resource "/one-time-password-sms/v1/send-code"
    When the HTTP "POST" request is sent
    Then the response property "$.status" is 403
    And the response property "$.code" is "ONE_TIME_PASSWORD_SMS.PHONE_NUMBER_NOT_ALLOWED"
    And the response property "$.message" contains a user friendly text
    And the response header "x-correlator" has same value as the request header "x-correlator"

@OTPvalidationAPI_06_send_code_phone_number_blocked
Scenario: Validation for failed scenario for a phone number that block SMS reception
    Given the request body property "$.phoneNumber" is set to a phone number that that has an active SMS barring
    And the phoneNumber cannot be identified by the token
    And the request body property "$.message" is set to config_var: "message"
    And the resource "/one-time-password-sms/v1/send-code"
    When the HTTP "POST" request is sent
    Then the response property "$.status" is 403
    And the response property "$.code" is "ONE_TIME_PASSWORD_SMS.PHONE_NUMBER_BLOCKED"
    And the response property "$.message" contains a user friendly text
    And the response header "x-correlator" has same value as the request header "x-correlator"

###########################
#  404 errors for send-code
###########################

@OTPvalidationAPI_404.1_send_code_phone_number_not_belong_to_operator
Scenario: Validation for failed scenario for a phone number that did not belong to the operator
    Given the request body property "$.phoneNumber" is set to a phone number that did not belong to the operator
    And the phoneNumber cannot be identified by the token
    And the request body property "$.message" is set to config_var: "message"
    And the resource "/one-time-password-sms/v1/send-code"
    When the HTTP "POST" request is sent
    Then the response property "$.status" is 404
    And the response property "$.code" is "NOT_FOUND"
    And the response property "$.message" contains a user friendly text
    And the response header "x-correlator" has same value as the request header "x-correlator"


################################################################################
# Rainy path scenarios for validate-code
################################################################################

# Following part describe scenario to test error code defined in the yaml
# These scenarios cover following http status: 400, 401, 404

# Following error code is not managed in scenarios
# -429 as it could not be easily tested
# -403 as there is no valid scenario

###############################
#  400 errors for validate-code
###############################

@OTPvalidationAPI_400.1_validate_code_no_request_body
Scenario: Missing request body
    Given the request body is not included
    And the resource "/one-time-password-sms/v1/validate-code"
    When the HTTP "POST" request is sent
    Then the response status code is 400
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" contains a user friendly text
    And the response header "x-correlator" has same value as the request header "x-correlator" 

@OTPvalidationAPI_400.2_validate_code_empty_request_body
Scenario: Empty object as request body for validate-code
    Given the request body is set to "{}"
    And the resource "/one-time-password-sms/v1/validate-code"
    When the HTTP "POST" request is sent
    Then the response status code is 400
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" contains a user friendly text
    And the response header "x-correlator" has same value as the request header "x-correlator"

@OTPvalidationAPI_400.3_validate_code_missing_authenticationId
Scenario: missing authenticationId as request parameter
    Given the request body property "$.authenticationId" is not valued
    And the request body property "$.code" is set to a format valid value
    And the resource "/one-time-password-sms/v1/validate-code"
    When the HTTP "POST" request is sent
    Then the response status code is 400
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" contains a user friendly text
    And the response header "x-correlator" has same value as the request header "x-correlator"

@OTPvalidationAPI_400.3_validate_code_missing_code
Scenario: missing code as request parameter
    Given an authenticationId has been retrieved from a send-code request
    And the request body property "$.code" is not valued
    And the resource "/one-time-password-sms/v1/validate-code"
    When the HTTP "POST" request is sent
    Then the response status code is 400
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" contains a user friendly text
    And the response header "x-correlator" has same value as the request header "x-correlator"

@OTPvalidationAPI_400.4_validate_code_exceed_code_max_length
Scenario: exceed the maxLength for code
    Given request body property "$.authenticationId" is set to the value from send-code request
    And the request body property "$.code" is set to "thisCodeExceedsTenCharacters"
    And the resource "/one-time-password-sms/v1/validate-code"
    When the HTTP "POST" request is sent
    Then the response status code is 400
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" contains a user friendly text
    And the response header "x-correlator" has same value as the request header "x-correlator"

@OTPvalidationAPI_400.5_validate_code_invalid_otp_scenario
Scenario: Validations for invalid otp validate-code scenario
    Given request body property "$.authenticationId" is set to the value from send-code request
    And the request body property "$.code" is set to a value distinct from the value received in the SMS
    And the resource "/one-time-password-sms/v1/validate-code"
    When the HTTP "POST" request is sent
    Then the response property "$.status" is 400
    And the response property "$.code" is "ONE_TIME_PASSWORD_SMS.INVALID_OTP"
    And the response property "$.message" contains a user friendly text
    And the response header "x-correlator" has same value as the request header "x-correlator"

@OTPvalidationAPI_400.6_validate_code_verification_expired_scenario_1
Scenario:  Validations for verification expired validate-code scenario
    Given request body property "$.authenticationId" is set to the value from send-code request
    And the request body property "$.code" is set to the received in the SMS
    And the resource "/one-time-password-sms/v1/validate-code"
    And the time elapsed since the send-code exceed the allowed time
    When the HTTP "POST" request is sent
    Then the response property "$.status" is 400
    And the response property "$.code" is "ONE_TIME_PASSWORD_SMS.VERIFICATION_EXPIRED"
    And the response property "$.message" contains a user friendly text
    And the response header "x-correlator" has same value as the request header "x-correlator"

@OTPvalidationAPI_400.7_validate_code_verification_expired_scenario_2
Scenario:  Validations for verification expired because a new one has been requested for the same phone number
    Given Two send-code request has been sequentially triggered for the same phoneNumber
    And request body property "$.authenticationId" is set to the value got for the first send-code request
    And the request body property "$.code" is set to the received in the SMS for this first request
    And the resource "/one-time-password-sms/v1/validate-code"
    When the HTTP "POST" request is sent
    Then the response property "$.status" is 400
    And the response property "$.code" is "ONE_TIME_PASSWORD_SMS.VERIFICATION_EXPIRED"
    And the response property "$.message" contains a user friendly text
    And the response header "x-correlator" has same value as the request header "x-correlator"

@OTPvalidationAPI_400.8_validate_code_verification_expired_scenario_3
Scenario:  Validations for verification expired because authenticationId is no longer valid because it has already been used
    Given a validate-code has been succesfully performed for a authenticationId
    And request body property "$.authenticationId" is valued again with this authenticationId
    And the request body property "$.code" is set to the code received in the SMS
    And the resource "/one-time-password-sms/v1/validate-code"
    When the HTTP "POST" request is sent
    Then the response property "$.status" is 400
    And the response property "$.code" is "ONE_TIME_PASSWORD_SMS.VERIFICATION_EXPIRED"
    And the response property "$.message" contains a user friendly text
    And the response header "x-correlator" has same value as the request header "x-correlator"

@OTPvalidationAPI_400.9_validate_code_verification_failed_scenario
Scenario:  Validations for verification failed validate-code scenario whe maximum number of attempts for this authenticationId was exceeded without providing a valid OTP
    Given an authenticationId has been retrieved from a send-code request
    And (config_var:"max_try"-1) calls with the request body property "$.code" set to a value distinct from the value received in the SMS were performed
    And the resource "/one-time-password-sms/v1/validate-code"
    When the HTTP "POST" request is sent
    Then the response property "$.status" is 400
    And the response property "$.code" is "ONE_TIME_PASSWORD_SMS.VERIFICATION_FAILED"
    And the response property "$.message" contains a user friendly text
    And the response header "x-correlator" has same value as the request header "x-correlator"

###############################
#  401 errors for validate-code
###############################

@OTPvalidationAPI_401.1_validate_code_no_authorization_header
Scenario: No Authorization header for calidate-code
    Given the header "Authorization" is removed
    And the resource "/one-time-password-sms/v1/validate-code"
    When the HTTP "POST" request is sent
    Then the response property "$.status" is 401
    And the response property "$.code" is "UNAUTHENTICATED"
    And the response property "$.message" contains a user friendly text
    And the response header "x-correlator" has same value as the request header "x-correlator"

@OTPvalidationAPI_401.2_validate_code_expired_access_token
Scenario: Expired access token for validate-code
    Given the header "Authorization" is set to an expired access token
    And the resource "/one-time-password-sms/v1/validate-code"
    When the HTTP "POST" request is sent
    Then the response property "$.status" is 401
    And the response property "$.code" is "UNAUTHENTICATED"
    And the response property "$.message" contains a user friendly text
    And the response header "x-correlator" has same value as the request header "x-correlator"

@OTPvalidationAPI_401.3_validate_code_invalid_access_token
Scenario: Invalid access token for validate-code
    Given the header "Authorization" is set to an invalid access token
    And the resource "/one-time-password-sms/v1/validate-code"
    When the HTTP "POST" request is sent
    Then the response property "$.status" is 401
    And the response property "$.code" is "UNAUTHENTICATED"
    And the response property "$.message" contains a user friendly text
    And the response header "x-correlator" has same value as the request header "x-correlator"

###############################
#  404 errors for validate-code
###############################

@OTPvalidationAPI_404_validate_code_resource_not_found
Scenario: resource not found
      Given the request body property "$.authenticationId" is set to an unknown value
      And the resource "/one-time-password-sms/v1/validate-code"
      When the HTTP "POST" request is sent
      Then the response property "$.status" is 404
      And the response property "$.code" is "NOT_FOUND"
      And the response header "x-correlator" has same value as the request header "x-correlator"
      And the response property "$.message" contains a user friendly text
