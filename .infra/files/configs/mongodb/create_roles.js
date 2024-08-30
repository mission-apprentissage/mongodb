const roleName = process.env['NAME'];
const dbName = process.env['DATABASE'];
const privileges = JSON.parse(process.env['PRIVILEGES'])

db = db.getSiblingDB(dbName);
const role = db.getRole(roleName);
if (!role) {
    db.createRole({
        role: roleName,
        privileges: [],
        roles: [],
    });
}

db.grantPrivilegesToRole(roleName, privileges);

