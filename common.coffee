BulkInterface = 
    defaultDelimiter: "	" # Tab, copied from Excel
    lookupCollection: (name) -> 
        if Meteor.isClient then window[name] else global[name]
    parse: (rawData, options) ->
        if options.delimiter
            parsedData = Papa.parse rawData,
                header: true
                delimiter: options.delimiter
        else
            # Papa Parse doesn't detect tabs pasted from Excel for some reason, so we have to check for that
            preview = Papa.parse rawData,
                header: true
                preview: 10
            if (_.any preview.errors, (err) -> err.code == "UndetectableDelimiter") or (_.any preview.errors, (err) -> err.code == "TooManyFields")
                # If the delimiter was not detectable, use the default delimiter
                parsedData = Papa.parse rawData,
                    header: true
                    delimiter: BulkInterface.defaultDelimiter #"\t" "   "
            else
                parsedData = Papa.parse rawData, header: true
        parsedData

Meteor.methods
    "BulkInterface.upsert": (collectionName, rows, key, fields) ->
        collection = BulkInterface.lookupCollection collectionName
        results = []
        rows.forEach (row) ->
            rowData =  _.pick(row, fields)
            if key
                selector = {}
                selector[key] = row[key]
                result = collection.upsert selector, $set: rowData#, (err, result) ->
                if result.insertedId
                    results.push key: row[key], _id: row._id, status: type: "inserted", insertedId: result.insertedId
                else
                    results.push key: row[key], _id: row._id, status: type: "updated", numberAffected: result.numberAffected
            else
                collection.insert rowData
        return results