
import axios from 'axios';

async function check() {
  try {
    const res = await axios.get('http://localhost:8081/api/v1/admin/sales/transactions/all');
    console.log(JSON.stringify(res.data.data.filter(t => t.delivery_items && t.delivery_items.length > 0), null, 2));
  } catch (e) {
    console.error(e.message);
  }
}

check();
