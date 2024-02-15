> :warning: ** Do not just copy this script and use it, you need to change a few things for this to work properly. **<br><br><br>
I am leaving this here incase someone wants to do the same thing, this example is running from our ITSM system TOPdesk.<br>
The main point to take from this is that you should be able to replace it quite easily with your own data source for Customer data.

# Modules used
* PSNetboxFunctions
* PSTopdeskFunctions (not needed if you do not use TOPdesk)

# Configuration
If you use TOPdesk then make sure the customer object in TOPdesk is pointing to the correct value in the script, also you need to copy the config_template.json file and create your own config.json file with your parameters.<br><br>If you do not use TOPdesk then I can ofcourse help out with pointers if needed, but you need to know your own data.

# What does it do
* We retrieve all customers from TOPdesk and Netbox
* Look through all customers in TOPdesk and check if it exists in Netbox, if not then create a new one.
* If the customer already exists then make sure it was changed in its source (TOPdesk) within the last 2 days, otherwise ignore it.
* Also when a customer is synched there are 2 tags created within Netbox, for us we call them 'topdesk-synced' and 'topdesk-synced-orphaned' these are updated on creation and updating
* If custom does not exist in Source anymore but is still Active in Netbox then set the tag 'topdesk-synced-orphaned'

# Questions
Send me a message if you want help with a integration or if you are missing a function.
