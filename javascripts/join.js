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


// I have also tried creating an id field which is numerical
// I have also tried butting the id field first in the array, although it is sorted differently in the result object. 

// console.log(lsoa_to_pcn_data)
// console.log(health_df)

// var result = join(lsoa_to_pcn_data, health_df, "LSOA21CD", "LSOA21CD", function(x, y) {
//     return {
//         LSOA21CD: y.LSOA21CD,
//         PCN_Name: x.PCN_name,
//         LTLA: y.LTLA,
//         Topic: x.Topic,
//         Category: x.Category,
//         Numerator: x.Numerator,
//         Proportion: x.Proportion,
//         Denominator: x.Denominator,
//         // brand: (lsoa_to_pcn_data !== undefined) ? lsoa_to_pcn_data.LSOA21CD : null
//     };
// });

//console.log(health_df)
// console.log(result);

// FIXME

// Get it working for maps
// https://stackoverflow.com/questions/44106015/combining-geojson-and-json-for-leaftlet