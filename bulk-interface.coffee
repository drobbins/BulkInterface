BulkInterface = 
    message: "Hello from BulkInterface"
    action: -> console.log BulkInterface.message


if Meteor.isClient
    Template.bulkInterface.events
        "change textarea[name=bulk-interface-value]": (e) ->
            rawData = $(e.target).val()
            parsedData = Papa.parse rawData, { header: true, delimiter: "	" }
            console.log "Parsed the data. Sample:", parsedData.data[0]