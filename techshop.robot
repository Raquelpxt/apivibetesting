*** Settings ***
Documentation     TechShop REST API Test Suite using RequestsLibrary
Library           RequestsLibrary
Library           Collections
Library           OperatingSystem
Suite Setup       Create API Session
Suite Teardown    Delete All Sessions

*** Variables ***
${BASE_URL}       %{BASE_URL=http://localhost:3000}
${EMAIL}          %{TEST_EMAIL}
${PASSWORD}       %{TEST_PASSWORD}

*** Keywords ***
Create API Session
    Create Session    techshop    ${BASE_URL}

Get Auth Token
    &{body}=          Create Dictionary    email=${EMAIL}    password=${PASSWORD}
    ${response}=      POST On Session      techshop          /auth/login    json=${body}    expected_status=200
    ${token}=         Set Variable         ${response.json()}[token]
    RETURN            ${token}

Get Auth Headers
    ${token}=         Get Auth Token
    &{headers}=       Create Dictionary    Authorization=Bearer ${token}    Content-Type=application/json
    RETURN            &{headers}

*** Test Cases ***
# ─── Auth ────────────────────────────────────────────────────────────────────

Login With Valid Credentials Returns Token
    [Tags]            auth    happy_path
    &{body}=          Create Dictionary    email=${EMAIL}    password=${PASSWORD}
    ${response}=      POST On Session      techshop          /auth/login    json=${body}    expected_status=200
    Dictionary Should Contain Key          ${response.json()}    token
    Dictionary Should Contain Key          ${response.json()}    user

Login With Wrong Password Returns 401
    [Tags]            auth    negative
    &{body}=          Create Dictionary    email=${EMAIL}    password=wrongpassword
    POST On Session   techshop             /auth/login       json=${body}    expected_status=401

Login With Missing Email Field Returns 400
    [Tags]            auth    negative
    &{body}=          Create Dictionary    password=${PASSWORD}
    POST On Session   techshop             /auth/login       json=${body}    expected_status=400

Login With Missing Password Field Returns 400
    [Tags]            auth    negative
    &{body}=          Create Dictionary    email=${EMAIL}
    POST On Session   techshop             /auth/login       json=${body}    expected_status=400

Login With Non-Existent Email Returns 401
    [Tags]            auth    negative
    &{body}=          Create Dictionary    email=nonexistent@techshop.com    password=password123
    POST On Session   techshop             /auth/login       json=${body}    expected_status=401

# ─── Products ────────────────────────────────────────────────────────────────

Get All Products Returns 200
    [Tags]            products    happy_path
    ${response}=      GET On Session       techshop          /products    expected_status=200
    ${products}=      Set Variable         ${response.json()}
    ${length}=        Get Length           ${products}
    Should Be True    ${length} > 0

Get Products Filter By Category Returns 200
    [Tags]            products    happy_path
    &{params}=        Create Dictionary    category=computers
    ${response}=      GET On Session       techshop          /products    params=${params}    expected_status=200
    ${products}=      Set Variable         ${response.json()}
    FOR    ${item}    IN                   @{products}
        Should Be Equal As Strings         ${item}[category]    computers
    END

Get Products With Non-Existent Category Returns Empty List
    [Tags]            products    negative
    &{params}=        Create Dictionary    category=nonexistentcategory
    ${response}=      GET On Session       techshop          /products    params=${params}    expected_status=200
    ${products}=      Set Variable         ${response.json()}
    ${length}=        Get Length           ${products}
    Should Be Equal As Integers            ${length}    0

Get Product With Valid ID Returns 200
    [Tags]            products    happy_path
    ${response}=      GET On Session       techshop          /products/1    expected_status=200
    Should Be Equal As Integers            ${response.json()}[id]    1

Get Product With Unknown ID Returns 404
    [Tags]            products    negative
    GET On Session    techshop             /products/999     expected_status=404

Get Product With Invalid ID Format Returns 400
    [Tags]            products    negative
    GET On Session    techshop             /products/abc     expected_status=400

# ─── Cart ────────────────────────────────────────────────────────────────────

Get Cart With Valid Auth Returns 200
    [Tags]            cart    happy_path
    &{headers}=       Get Auth Headers
    ${response}=      GET On Session       techshop          /cart    headers=${headers}    expected_status=200
    Dictionary Should Contain Key          ${response.json()}    items
    Dictionary Should Contain Key          ${response.json()}    total

Get Cart Without Auth Returns 401
    [Tags]            cart    negative
    GET On Session    techshop             /cart             expected_status=401

Get Cart With Invalid Token Returns 401
    [Tags]            cart    negative
    &{bad_headers}=   Create Dictionary    Authorization=Bearer invalid_token_123
    GET On Session    techshop             /cart             headers=${bad_headers}    expected_status=401

Add Item To Cart With Valid Token And Data Returns 201
    [Tags]            cart    happy_path
    &{headers}=       Get Auth Headers
    &{body}=          Create Dictionary    productId=${1}    quantity=${2}
    ${response}=      POST On Session      techshop          /cart    json=${body}    headers=${headers}    expected_status=201

Add Item To Cart With Negative Quantity Returns 400
    [Tags]            cart    negative
    &{headers}=       Get Auth Headers
    &{body}=          Create Dictionary    productId=${1}    quantity=${-5}
    POST On Session   techshop             /cart             json=${body}    headers=${headers}    expected_status=400

Add Item To Cart With Quantity Zero Returns 400
    [Tags]            cart    negative
    &{headers}=       Get Auth Headers
    &{body}=          Create Dictionary    productId=${1}    quantity=${0}
    POST On Session   techshop             /cart             json=${body}    headers=${headers}    expected_status=400

Add Item To Cart Missing Required Fields Returns 400
    [Tags]            cart    negative
    &{headers}=       Get Auth Headers
    &{body}=          Create Dictionary    quantity=${1}
    POST On Session   techshop             /cart             json=${body}    headers=${headers}    expected_status=400

Add Item To Cart Without Auth Returns 401
    [Tags]            cart    negative
    &{body}=          Create Dictionary    productId=${1}    quantity=${2}
    POST On Session   techshop             /cart             json=${body}    expected_status=401

Add Non-Existent Product To Cart Returns 404
    [Tags]            cart    negative
    &{headers}=       Get Auth Headers
    &{body}=          Create Dictionary    productId=${9999}    quantity=${1}
    POST On Session   techshop             /cart             json=${body}    headers=${headers}    expected_status=404

Update Cart Item Quantity Returns 200
    [Tags]            cart    happy_path
    &{headers}=       Get Auth Headers
    &{add_body}=      Create Dictionary    productId=${1}    quantity=${1}
    POST On Session   techshop             /cart             json=${add_body}    headers=${headers}    expected_status=any
    &{update_body}=   Create Dictionary    quantity=${3}
    ${response}=      PUT On Session       techshop          /cart/1    json=${update_body}    headers=${headers}    expected_status=200

Update Cart Item Quantity Less Than 1 Returns 400
    [Tags]            cart    negative
    &{headers}=       Get Auth Headers
    &{body}=          Create Dictionary    quantity=${0}
    PUT On Session    techshop             /cart/1           json=${body}    headers=${headers}    expected_status=400

Update Cart Item Missing Quantity Returns 400
    [Tags]            cart    negative
    &{headers}=       Get Auth Headers
    &{body}=          Create Dictionary
    PUT On Session    techshop             /cart/1           json=${body}    headers=${headers}    expected_status=400

Update Cart Item With Non-Existent ID Returns 404
    [Tags]            cart    negative
    &{headers}=       Get Auth Headers
    &{body}=          Create Dictionary    quantity=${2}
    PUT On Session    techshop             /cart/9999        json=${body}    headers=${headers}    expected_status=404

Update Cart Item Without Auth Returns 401
    [Tags]            cart    negative
    &{body}=          Create Dictionary    quantity=${2}
    PUT On Session    techshop             /cart/1           json=${body}    expected_status=401

Update Cart Item With Invalid Token Returns 401
    [Tags]            cart    negative
    &{bad_headers}=   Create Dictionary    Authorization=Bearer invalid_token_123
    &{body}=          Create Dictionary    quantity=${2}
    PUT On Session    techshop             /cart/1           json=${body}    headers=${bad_headers}    expected_status=401

Remove Cart Item With Valid Auth Returns 200
    [Tags]            cart    happy_path
    &{headers}=       Get Auth Headers
    &{add_body}=      Create Dictionary    productId=${1}    quantity=${1}
    POST On Session   techshop             /cart             json=${add_body}    headers=${headers}    expected_status=any
    ${response}=      DELETE On Session    techshop          /cart/1    headers=${headers}    expected_status=200

Remove Cart Item Without Auth Returns 401
    [Tags]            cart    negative
    DELETE On Session    techshop          /cart/1           expected_status=401

Remove Cart Item With Invalid Token Returns 401
    [Tags]            cart    negative
    &{bad_headers}=   Create Dictionary    Authorization=Bearer invalid_token_123
    DELETE On Session    techshop          /cart/1           headers=${bad_headers}    expected_status=401

Remove Cart Item With Non-Existent ID Returns 404
    [Tags]            cart    negative
    &{headers}=       Get Auth Headers
    DELETE On Session    techshop          /cart/9999        headers=${headers}    expected_status=404

# ─── Orders ──────────────────────────────────────────────────────────────────

Get Orders With Valid Auth Returns 200
    [Tags]            orders    happy_path
    &{headers}=       Get Auth Headers
    ${response}=      GET On Session       techshop          /orders    headers=${headers}    expected_status=200

Get Orders Without Auth Returns 401
    [Tags]            orders    negative
    GET On Session    techshop             /orders           expected_status=401

Get Orders With Invalid Token Returns 401
    [Tags]            orders    negative
    &{bad_headers}=   Create Dictionary    Authorization=Bearer invalid_token_123
    GET On Session    techshop             /orders           headers=${bad_headers}    expected_status=401

Place Order With Valid Data Returns 201
    [Tags]            orders    happy_path
    &{headers}=       Get Auth Headers
    &{item1}=         Create Dictionary    productId=${1}    quantity=${2}
    @{items}=         Create List          ${item1}
    &{shipping}=      Create Dictionary    firstName=Jane    lastName=Doe    email=jane@example.com    phone=0412345678
    &{payment}=       Create Dictionary    cardNumber=4111111111111111    expiryDate=12/28    cvv=123
    &{order_body}=    Create Dictionary    items=${items}    shipping=${shipping}    payment=${payment}
    ${response}=      POST On Session      techshop          /orders    json=${order_body}    headers=${headers}    expected_status=201
    Dictionary Should Contain Key          ${response.json()}    id
    Dictionary Should Contain Key          ${response.json()}    status

Place Order With Expired Card Returns 400
    [Tags]            orders    negative
    &{headers}=       Get Auth Headers
    &{item1}=         Create Dictionary    productId=${1}    quantity=${2}
    @{items}=         Create List          ${item1}
    &{shipping}=      Create Dictionary    firstName=Jane    lastName=Doe    email=jane@example.com    phone=0412345678
    &{payment}=       Create Dictionary    cardNumber=4111111111111111    expiryDate=01/20    cvv=123
    &{order_body}=    Create Dictionary    items=${items}    shipping=${shipping}    payment=${payment}
    POST On Session   techshop             /orders           json=${order_body}    headers=${headers}    expected_status=400

Place Order With Invalid Card Number Returns 400
    [Tags]            orders    negative
    &{headers}=       Get Auth Headers
    &{item1}=         Create Dictionary    productId=${1}    quantity=${1}
    @{items}=         Create List          ${item1}
    &{shipping}=      Create Dictionary    firstName=Jane    lastName=Doe    email=jane@example.com    phone=0412345678
    &{payment}=       Create Dictionary    cardNumber=1234    expiryDate=12/28    cvv=123
    &{order_body}=    Create Dictionary    items=${items}    shipping=${shipping}    payment=${payment}
    POST On Session   techshop             /orders           json=${order_body}    headers=${headers}    expected_status=400

Place Order With Missing Shipping Fields Returns 400
    [Tags]            orders    negative
    &{headers}=       Get Auth Headers
    &{item1}=         Create Dictionary    productId=${1}    quantity=${1}
    @{items}=         Create List          ${item1}
    &{shipping}=      Create Dictionary    firstName=Jane
    &{payment}=       Create Dictionary    cardNumber=4111111111111111    expiryDate=12/28    cvv=123
    &{order_body}=    Create Dictionary    items=${items}    shipping=${shipping}    payment=${payment}
    POST On Session   techshop             /orders           json=${order_body}    headers=${headers}    expected_status=400

Place Order With Missing Payment Fields Returns 400
    [Tags]            orders    negative
    &{headers}=       Get Auth Headers
    &{item1}=         Create Dictionary    productId=${1}    quantity=${1}
    @{items}=         Create List          ${item1}
    &{shipping}=      Create Dictionary    firstName=Jane    lastName=Doe    email=jane@example.com    phone=0412345678
    &{payment}=       Create Dictionary    cardNumber=4111111111111111    expiryDate=12/28
    &{order_body}=    Create Dictionary    items=${items}    shipping=${shipping}    payment=${payment}
    POST On Session   techshop             /orders           json=${order_body}    headers=${headers}    expected_status=400

Place Order With Empty Items Array Returns 400
    [Tags]            orders    negative
    &{headers}=       Get Auth Headers
    @{items}=         Create List
    &{shipping}=      Create Dictionary    firstName=Jane    lastName=Doe    email=jane@example.com    phone=0412345678
    &{payment}=       Create Dictionary    cardNumber=4111111111111111    expiryDate=12/28    cvv=123
    &{order_body}=    Create Dictionary    items=${items}    shipping=${shipping}    payment=${payment}
    POST On Session   techshop             /orders           json=${order_body}    headers=${headers}    expected_status=400

Place Order Without Auth Returns 401
    [Tags]            orders    negative
    &{item1}=         Create Dictionary    productId=${1}    quantity=${1}
    @{items}=         Create List          ${item1}
    &{shipping}=      Create Dictionary    firstName=Jane    lastName=Doe    email=jane@example.com    phone=0412345678
    &{payment}=       Create Dictionary    cardNumber=4111111111111111    expiryDate=12/28    cvv=123
    &{order_body}=    Create Dictionary    items=${items}    shipping=${shipping}    payment=${payment}
    POST On Session   techshop             /orders           json=${order_body}    expected_status=401

Place Order With Invalid Token Returns 401
    [Tags]            orders    negative
    &{bad_headers}=   Create Dictionary    Authorization=Bearer invalid_token_123
    &{item1}=         Create Dictionary    productId=${1}    quantity=${1}
    @{items}=         Create List          ${item1}
    &{shipping}=      Create Dictionary    firstName=Jane    lastName=Doe    email=jane@example.com    phone=0412345678
    &{payment}=       Create Dictionary    cardNumber=4111111111111111    expiryDate=12/28    cvv=123
    &{order_body}=    Create Dictionary    items=${items}    shipping=${shipping}    payment=${payment}
    POST On Session   techshop             /orders           json=${order_body}    headers=${bad_headers}    expected_status=401
