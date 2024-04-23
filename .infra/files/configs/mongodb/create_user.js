const username = process.env['USERNAME'];
const password = process.env['PASSWORD'];
const database = process.env['DATABASE'];
const rolesStr = process.env['ROLES'];

const roles = rolesStr.split(',').map(role => ({ role, db: database }));

db = db.getSiblingDB(database);
const user = db.getUser(username);
if (!user) {
    db.createUser({
        user: username,
        pwd: password,
        roles: roles,
    });
    console.log(`User ${username} created`);
} else {
    db.updateUser(username, {
        pwd: password,
        roles: roles,
    });
    console.log(`User ${username} updated`);
}
