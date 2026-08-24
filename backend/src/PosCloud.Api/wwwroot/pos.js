const TENANT='00000000-0000-0000-0000-000000000000';
let cart=[], allProducts=[];
document.querySelectorAll('nav button').forEach(b=>b.addEventListener('click',()=>{
  document.querySelectorAll('nav button').forEach(x=>x.classList.remove('active'));b.classList.add('active');
  document.querySelectorAll('main section').forEach(s=>s.style.display='none');
  document.getElementById(b.dataset.tab).style.display='block';
}));
async function jget(p){return (await fetch(p)).json()}
async function loadDash(){
  const s=await jget('/api/reports/daily-sales?tenantId='+TENANT);
  document.getElementById('netSales').textContent=(s.data?.total??0)+' JOD';
  document.getElementById('salesCount').textContent=s.data?.count??0;
  const st=await jget('/api/inventory/stock?tenantId='+TENANT);
  document.getElementById('stockInfo').textContent=(st.data?.length??0)+' مادة';
}
async function loadProducts(){
  const r=await jget('/api/products?tenantId='+TENANT+'&page=1&pageSize=50');
  allProducts=r.data||[];
  const tb=document.getElementById('productsBody');
  tb.innerHTML='';
  allProducts.forEach(p=>{
    const sku=p.sku||''; const name=p.nameAr||p.name_ar||p.nameEn||''; const price=p.sellPrice||p.sell_price||''; const bc=p.barcodeMain||p.barcode_main||'';
    const tr=document.createElement('tr');
    tr.innerHTML='<td>'+sku+'</td><td>'+name+'</td><td>'+price+'</td><td>'+bc+'</td>';
    tb.appendChild(tr);
  });
  renderGrid();
}
function renderGrid(){
  const g=document.getElementById('productGrid'); if(!g) return;
  g.innerHTML='';
  allProducts.forEach(p=>{
    const d=document.createElement('div'); d.className='card'; d.style='cursor:pointer;text-align:center';
    const name=p.nameAr||p.nameEn||p.sku; const price=p.sellPrice||p.sell_price;
    d.innerHTML='<div style=font-weight:700>'+name+'</div><div class=muted>'+price+' JOD</div>';
    d.onclick=()=>addToCart(p); g.appendChild(d);
  });
}
function addToCart(p){
  const f=cart.find(c=>c.id===p.id);
  if(f) f.qty++;
  else cart.push({id:p.id,name:p.nameAr||p.nameEn||p.sku,price:Number(p.sellPrice||p.sell_price||0),qty:1,tax:Number(p.taxRate||p.tax_rate||0)});
  renderCart();
}
