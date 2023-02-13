
// http://learnjsdata.com/combine_data.html

function join(lookupTable, mainTable, lookupKey, mainKey, select) {
    var l = lookupTable.length,
        m = mainTable.length,
        lookupIndex = [],
        output = [];
    for (var i = 0; i < l; i++) { // loop through l items
        var row = lookupTable[i];
        lookupIndex[row[lookupKey]] = row; // create an index for lookup table
    }
    for (var j = 0; j < m; j++) { // loop through m items
        var y = mainTable[j];
        var x = lookupIndex[y[mainKey]]; // get corresponding row from lookupTable
        output.push(select(y, x)); // select only the columns you need
    }
    return output;
};

// Because above defined function creates an index for the lookupTable (in our case lsoa_to_pcn_data) in the first iteration, it runs considerably faster than the previously shown method. Also, via a callback, it allows us to directly define which keys (or "attributes") we want to retain in the resulting, joined array (output). It is used like so:


var result = join(lsoa_to_pcn_data, health_df, "LSOA21CD", "LSOA21CD", function(lookup, main) {
    return {
        LSOA21CD: main.LSOA21CD,
        PCN_Name: lookup.PCN_Name,
        LTLA: lookup.LTLA,
        Topic: main.Topic,
        Category: main.Category,
        Numerator: main.Numerator,
        Proportion: main.Proportion,
        Denominator: main.Denominator,
        // brand: (lsoa_to_pcn_data !== undefined) ? lsoa_to_pcn_data.LSOA21CD : null
    };
});

console.log(result);

// FIXME

// Get it working for maps
// https://stackoverflow.com/questions/44106015/combining-geojson-and-json-for-leaftlet