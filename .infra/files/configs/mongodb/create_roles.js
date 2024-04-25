db = db.getSiblingDB('admin');
const role = db.getRole('any');
if (!role) {
    db.createRole({
        role: 'any',
        privileges: [],
        roles: [],
    });
}

db.grantPrivilegesToRole('any', [{ resource: { anyResource: true }, actions: ['anyAction'] }]);
