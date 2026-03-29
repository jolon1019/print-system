const bcrypt = require('bcryptjs');

const password = '123456';
const hash = bcrypt.hashSync(password, 10);

console.log('密码:', password);
console.log('Hash:', hash);
console.log('');
console.log('更新SQL:');
console.log(`UPDATE public.users SET password = '${hash}' WHERE username IN ('admin', 'user1', 'user2');`);
