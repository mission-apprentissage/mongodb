// This script is used to initialze a brand new replica set
try {   
    rs.status().ok
} catch (e) { 
    if (e.code === 94) {
        rs.initiate({});
    } else {
        throw e;
    }
}