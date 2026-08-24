async function scanAdd(){
  const v=document.getElementById('scanInput').value.trim(); if(!v) return;
  let p=allProducts.find(x=> (x.barcodeMain||x.barcode_main)===v || (x.sku||'').toLowerCase()===v.toLowerCase() || (x.nameAr||'').includes(v));
  if(!p){ try{ const r=await jget('/api/products/barcode/'+encodeURIComponent(v)+'?tenantId='+TENANT); if(r.data) p=r.data; }catch(e){} }
  if(p) addToCart(p); else alert('غير موجود: '+v);
  document.getElementById('scanInput').value='';
}
function renderCart(){
  const tb=document.getElementById('cartBody'); tb.innerHTML='';
  let sub=0,tax=0;
  cart.forEach((c,i)=>{
    const line=c.price*c.qty; const t=line*c.tax; sub+=line; tax+=t;
    const tr=document.createElement('tr');
    tr.innerHTML='<td>'+c.name+'</td><td><input type=number value='+c.qty+' min=1 style=width:60px onchange="cart['+i+'].qty=Number(this.value);renderCart()"></td><td>'+c.price.toFixed(2)+'</td><td><button onclick="cart.splice('+i+',1);renderCart()">x</button></td>';
    tb.appendChild(tr);
  });
  const disc=Number(document.getElementById('discountTotal').value||0);
  document.getElementById('cartSubtotal').textContent=sub.toFixed(2);
  document.getElementById('cartTax').textContent=tax.toFixed(2);
  const grand=sub+tax-disc;
  document.getElementById('cartTotal').textContent=grand.toFixed(2);
  document.getElementById('payAmount').value=grand.toFixed(2);
}
function clearCart(){ cart=[]; renderCart(); document.getElementById('posOut').textContent=''; const r=document.getElementById('receipt'); if(r) r.style.display='none'; }
async function checkout(){
  if(!cart.length) return alert('السلة فارغة');
  const branchId=document.getElementById('posBranch').value.trim(); if(!branchId) return alert('أدخل BranchId');
  const discountTotal=Number(document.getElementById('discountTotal').value||0);
  const method=document.getElementById('payMethod').value;
  const payAmount=Number(document.getElementById('payAmount').value);
  const lines=cart.map(c=>({productId:c.id,qty:c.qty}));
  const body={tenantId:TENANT,branchId,customerId:null,discountTotal,lines,payments:[{method,amount:payAmount}]};
  const res=await fetch('/api/sales',{method:'POST',headers:{'Content-Type':'application/json','Idempotency-Key':'pos-'+Date.now()},body:JSON.stringify(body)}).then(r=>r.json());
  document.getElementById('posOut').textContent=JSON.stringify(res,null,2);
  if(res.data){
    const s=res.data; let rec='*** POS Cloud ***\nالإيصال: '+(s.receiptNo||s.receipt_no)+'\n'+new Date().toLocaleString('ar')+'\n----------------\n';
    cart.forEach(c=> rec+=c.name+' x'+c.qty+' = '+(c.price*c.qty).toFixed(2)+' JOD\n');
    rec+='----------------\nالإجمالي: '+document.getElementById('cartTotal').textContent+' JOD\nشكرا';
    const el=document.getElementById('receipt'); el.textContent=rec; el.style.display='block'; window.print();
    cart=[]; renderCart(); loadDash();
  }
}
async function loadSales(){
  const r=await jget('/api/sales?tenantId='+TENANT+'&page=1&pageSize=20');
  const tb=document.getElementById('salesBody'); tb.innerHTML='';
  (r.data||[]).forEach(s=>{
    const tr=document.createElement('tr');
    tr.innerHTML='<td>'+(s.receiptNo||s.receipt_no||'')+'</td><td>'+(s.grandTotal||s.grand_total||'')+'</td><td>'+String(s.createdAt||s.created_at||'').slice(0,19)+'</td>';
    tb.appendChild(tr);
  });
}
async function loadBranches(){
  const r=await jget('/api/branches?tenantId='+TENANT);
  const tb=document.getElementById('branchesBody'); tb.innerHTML='';
  (r.data||[]).forEach(b=>{
    const tr=document.createElement('tr');
    tr.innerHTML='<td>'+(b.code||'')+'</td><td>'+(b.name||'')+'</td><td style=font-size:.65rem>'+(b.id||'')+'</td><td><button class=btn onclick="document.getElementById(\'posBranch\').value=\''+b.id+'\'">استخدم</button></td>';
    tb.appendChild(tr);
  });
  if(r.data&&r.data[0]) document.getElementById('posBranch').value=r.data[0].id;
}
async function seedDemo(){
  const demos=[{nameAr:'خبز عربي',sku:'BRD-001',price:0.5,barcode:'100001'},{nameAr:'حليب 1ل',sku:'MLK-001',price:1.2,barcode:'100002'},{nameAr:'ماء 500مل',sku:'WTR-001',price:0.3,barcode:'100003'},{nameAr:'شاي',sku:'TEA-001',price:2.5,barcode:'100004'},{nameAr:'سكر 1كغ',sku:'SUG-001',price:1.0,barcode:'100005'}];
  for(const d of demos){
    await fetch('/api/products',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({tenantId:TENANT,categoryId:'00000000-0000-0000-0000-000000000000',nameAr:d.nameAr,nameEn:d.nameAr,sku:d.sku,barcodeMain:d.barcode,unit:'pcs',costPrice:d.price*0.7,sellPrice:d.price,taxRate:0.0,isActive:true})}).then(r=>r.json()).then(j=>document.getElementById('pOut').textContent=JSON.stringify(j,null,2));
  }
  loadProducts();
}
async function createProduct(){
  const body={tenantId:TENANT,categoryId:'00000000-0000-0000-0000-000000000000',nameAr:document.getElementById('pNameAr').value,nameEn:document.getElementById('pNameAr').value,sku:document.getElementById('pSku').value,barcodeMain:document.getElementById('pBarcode').value||null,unit:'pcs',costPrice:Number(document.getElementById('pPrice').value||0)*0.7,sellPrice:Number(document.getElementById('pPrice').value||0),taxRate:0,isActive:true};
  const r=await fetch('/api/products',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(body)}).then(x=>x.json());
  document.getElementById('pOut').textContent=JSON.stringify(r,null,2);
  if(r.data){
    const st=Number(document.getElementById('pStock').value||0);
    if(st>0){
      const br=document.getElementById('posBranch').value||(await jget('/api/branches?tenantId='+TENANT)).data?.[0]?.id;
      if(br) await fetch('/api/inventory/movements',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({tenantId:TENANT,branchId:br,productId:r.data.id,type:'adjust',qtyDelta:st})}).then(x=>x.json());
    }
    loadProducts();
  }
}
loadDash(); loadProducts(); loadBranches();
