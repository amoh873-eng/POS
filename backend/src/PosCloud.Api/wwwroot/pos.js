const TENANT='00000000-0000-0000-0000-000000000000';
let cart=[], allProducts=[];
// nav now handled by .side buttons in index.html — keep for compat if old nav exists
document.querySelectorAll('nav button').forEach(b=>b.addEventListener('click',()=>{
  document.querySelectorAll('nav button').forEach(x=>x.classList.remove('active'));b.classList.add('active');
  const t=b.dataset.tab;
  document.querySelectorAll('main section').forEach(s=>s.classList.add('hidden'));
  const el=document.getElementById(t); if(el) el.classList.remove('hidden');
  if(t==='pos') document.getElementById('posSection').classList.remove('hidden');
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
function imgFor(p){ return 'https://picsum.photos/seed/'+(p.sku||p.id||'x')+'/300/200'; }
function renderGrid(){
  const g=document.getElementById('productGrid'); if(!g) return;
  g.innerHTML='';
  allProducts.forEach(p=>{
    const name=p.nameAr||p.nameEn||p.sku; const price=p.sellPrice||p.sell_price||0;
    const added=cart.some(c=>c.id===p.id);
    const d=document.createElement('div'); d.className='pcard';
    d.innerHTML='<img src="'+imgFor(p)+'" alt=""/><div style="font-weight:800;margin-top:6px">'+name+'</div><div class="size">S | M | L</div><button class="btn '+(added?'added':'ghost')+' small add" style="width:100%">'+(added?'Added':'Add')+'</button>';
    const btn=d.querySelector('button'); btn.onclick=(e)=>{e.stopPropagation(); addToCart(p); renderGrid();};
    d.onclick=()=>{ addToCart(p); renderGrid(); };
    g.appendChild(d);
  });
}
function addToCart(p){
  const f=cart.find(c=>c.id===p.id);
  if(f) f.qty++;
  else cart.push({id:p.id,name:p.nameAr||p.nameEn||p.sku,price:Number(p.sellPrice||p.sell_price||0),qty:1,tax:Number(p.taxRate||p.tax_rate||0),img:imgFor(p)});
  renderCart(); renderGrid();
}
