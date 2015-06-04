BulkInterface = 
    defaultDelimiter: "	" # Tab, copied from Excel
    action: -> console.log BulkInterface.message

if Meteor.isClient
    Template.bulkInterface.events
        "change textarea[name=bulk-interface-value]": (e) ->
            rawData = $(e.target).val()

            # Papa Parse doesn't detect tabs pasted from Excel for some reason, so we have to check for that
            preview = Papa.parse rawData,
                header: true
                preview: 10
            if (_.any preview.errors, (err) -> err.code == "UndetectableDelimiter")
                # If the delimiter was not detectable, use the default delimiter
                parsedData = Papa.parse rawData,
                    header: true
                    delimiter: BulkInterface.defaultDelimiter #"\t" "	"
            else
                parsedData = Papa.parse rawData, header: true

            console.log "Parsed the data. Sample:", parsedData.data[0]
            BulkInterface.parsedDataCollection = @parsedDataCollection = new Mongo.Collection null
            parsedData.data.forEach (row) => @parsedDataCollection.insert row