const roleName = process.env['NAME'];
const privileges = JSON.parse(process.env['PRIVILEGES'])

db = db.getSiblingDB('admin');
const role = db.getRole(roleName);
if (!role) {
    db.createRole({
        role: roleName,
        privileges: [],
        roles: [],
    });
}

db.grantPrivilegesToRole(roleName, privileges);

