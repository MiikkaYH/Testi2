*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and images.
Library     RPA.Browser.Selenium
Library     RPA.Excel.Files
Library     RPA.HTTP
Library     RPA.PDF
Library     RPA.Tables
Library     RPA.Archive
Library     RPA.Dialogs
Library     RPA.FileSystem
Library     RPA.Robocorp.Vault

# +
*** Keywords ***
 

Open the robot order website and ask for name

    ${secret}=    Get Secret    important
    Open Available Browser    ${secret}[website]
    Add heading    Who is asking for their robot army?
    Add text input    name    label= The new emperors name
    
    ${answer}=    Run dialog
    
    [Return]    ${answer.name}    

Get orders

    ${secret}=    Get Secret    important

    Download    ${secret}[orderpile]    overwrite=True
    
    ${Table}=    Read table from CSV    orders.csv    header=True
    
    [Return]    ${Table}
    

Close the annoying modal
    Click Button    OK
    
    
Fill the form
    [Arguments]    ${row}
    Click Element  head
    Select From List By Value    head   ${row}[Head] 
    Select Radio Button    body    ${row}[Body]
    Input Text    xpath: //input[@type='number']     ${row}[Legs]
    Input Text    address    ${row}[Address]       


Preview the robot
    Click Button    preview


Submit the order
    Click Button    order
    
    Run Keyword And Continue On Failure    Submit the order


Store the receipt as a PDF file
    [Arguments]    ${row}
    
    
    ${dir}=     Does Directory Not Exist    ${CURDIR}${/}output
    
    IF    ${dir} == True
        Create Directory    ${CURDIR}${/}output
    END
    
    Wait Until Element Is Visible    id:receipt
    
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    
    Html To Pdf    ${receipt_html}    ${CURDIR}${/}output${/}${row}.pdf


Take a screenshot of the robot
    [Arguments]    ${row}

    Wait Until Element Is Visible    id:robot-preview-image
    
    ${robot_png}=    Get Element Attribute    id:robot-preview-image    outerHTML

    Screenshot    id:robot-preview-image    ${CURDIR}${/}output${/}${row}bot.png


Embed the robot screenshot to the receipt PDF file

    [Arguments]    ${row}
    
    ${files}=    Create List    ${CURDIR}${/}output${/}${row}.pdf    ${CURDIR}${/}output${/}${row}bot.png
    
    ${dir}=     Does Directory Not Exist    ${CURDIR}${/}output${/}PDFS
    
    IF    ${dir} == True
        Create Directory    ${CURDIR}${/}output${/}PDFS
    END
    
    Add Files To Pdf    ${files}    ${CURDIR}${/}output${/}PDFS${/}order${row}.pdf


Go to order another robot

    Click Button    order-another


Create a Zip file of the receipts
    [Arguments]    ${name}
    Archive Folder With Zip    ${CURDIR}${/}output${/}PDFS    ${name}Orders.zip

# -

*** Tasks ***
Order robots from RobotSparebin Industries Inc
    ${name}=    Open the robot order website and ask for name
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file   ${row}[Order number]
        Go to order another robot
    END
    Create a ZIP file of the receipts   ${name}
