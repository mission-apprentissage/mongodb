const roleName = process.env['NAME'];
const dbName = process.env['DATABASE'];
const privileges = JSON.parse(process.env['PRIVILEGES'])
const roles = JSON.parse(process.env['ROLES'])

db = db.getSiblingDB(dbName);
const role = db.getRole(roleName);
if (!role) {
    db.createRole({
        role: roleName,
        privileges: [],
        roles: [],
    });
}

if (privileges.length > 0) {
    db.grantPrivilegesToRole(roleName, privileges);
}

if (roles.length > 0) {
    db.grantRolesToRole(roleName, roles);
}
