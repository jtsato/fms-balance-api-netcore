print('Start #################################################################');

db = new Mongo().getDB("balances-mongodb");

db.createUser({
    user: 'xunit',
    pwd: 'xunit',
    roles: [
        {
            role: 'readWrite',
            db: 'balances-mongodb',
        },
    ],
});

db.createCollection('balances', {capped: false});
db.createCollection('balances_sequences', {capped: false});

print('End #################################################################');
