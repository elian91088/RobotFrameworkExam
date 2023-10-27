*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.

Library    RPA.Browser.Selenium    auto_close=${False}
Library    RPA.HTTP
Library    RPA.Tables
Library    RPA.PDF
Library    RPA.Netsuite
Library    OperatingSystem
Library    RPA.Archive

*** Tasks ***
Get Orders 
    Open Web Browser
    Getting csv file

Get the receipts
    Getting the Robots

Archive Ouput And Close
    Zip the files
    [Teardown]    CleanUp
   

*** Keywords ***

Open Web Browser
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order    maximized=${True}
Getting csv file
    Download    https://robotsparebinindustries.com/orders.csv

Getting the Robots
    @{dataCSV}=    Read table from CSV    orders.csv    header=true    columns=['Order number', 'Head', 'Body', 'Legs', 'Address']    dialect=excel
    
    FOR    ${dataRow}    IN     @{dataCSV}
        Build Robot    ${dataRow}
    END

Build Robot 
    [Arguments]    ${row}
    
    Wait Until Element Is Visible    class:alert-buttons
    Click Button    OK
    Select From List By Value    head    ${row}[Head]   
    RPA.Browser.Selenium.Click Element    id:id-body-${row}[Body]   
    Input Text    xpath:/html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${row}[Legs] 
    Input Text    id:address    ${row}[Address]
    
    Wait Until Keyword Succeeds    3x    5000ms    Click Element    id:preview
    
    Wait Until Element Is Visible    id:robot-preview-image
    Click Element    id:order

    ${ReceiptVisible} =     Is Element Visible    id:receipt

    WHILE    ${ReceiptVisible} == $False
        Wait Until Keyword Succeeds    3x    5000ms    Click Element    id:order
        ${ReceiptVisible} =     Is Element Visible    id:receipt
    END
 
    Getting the receipt    ${row}[Address]
    Click Button    id:order-another
    
Getting the receipt
    [Arguments]    ${robotAddres}
    ${htmlReceipt}=    Get Element Attribute    id:receipt    outerHTML
    Scroll Element Into View    id:robot-preview-image
    Screenshot    id:robot-preview-image    ${OUTPUT_DIR}${/}${robotAddres}.png
    
    ${robotImage}=    Create List    ${OUTPUT_DIR}${/}${robotAddres}.png

    Html To Pdf    ${htmlReceipt}    ${OUTPUT_DIR}${/}RECEIPTS${/}${robotAddres}.PDF
    Add Files To Pdf    ${robotImage}    ${OUTPUT_DIR}${/}RECEIPTS${/}${robotAddres}.PDF    append=${True}    
    
    Remove File    ${OUTPUT_DIR}${/}${robotAddres}.png

Zip the files
    Log    LA RUTA ES:${OUTPUT_DIR}${/}RECEIPTS
    Archive Folder With Zip	    ${OUTPUT_DIR}${/}RECEIPTS    robotsReceipt.zip    include=*.pdf
    
CleanUp
    Log    Fin del Robot
    Close Browser