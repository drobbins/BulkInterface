BulkInterface = 
    defaultDelimiter: "	" # Tab, copied from Excel
    action: -> console.log BulkInterface.message

if Meteor.isClient

    Template.bulkInterface.onCreated ->
        # Set up reactive vars for later use
        @data.parsedDataCollection = new Mongo.Collection null
        @data.status = new ReactiveVar "Waiting for Data"
        @data.fields = new ReactiveVar null

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

            # Populate the data object with a few parameters
            @status.set "Parsed"
            @fields.set parsedData.meta.fields

            BulkInterface.parsedDataCollection = @parsedDataCollection
            parsedData.data.forEach (row) => @parsedDataCollection.insert row

            $(".bulk-interface-table").dataTable
                data: @parsedDataCollection.find().fetch()
                columns: @fields.get().map (field) -> data: field, title: field

    Template.bulkInterface.helpers
        count: -> @parsedDataCollection.find().count()
        fields: -> @fields.get()
        rows: -> @parsedDataCollection.find()