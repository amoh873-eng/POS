async function scanAdd(){
  const v=(document.getElementById('searchInput')?.value || document.getElementById('scanInput')?.value || '').trim(); if(!v) return;
  let p=allProducts.find(x=> (x.barcodeMain||x.barcode_main)===v || (x.sku||'').toLowerCase()===v.toLowerCase() || (x.nameAr||'').includes(v) || (x.nameEn||'').toLowerCase().includes(v.toLowerCase()));
  if(!p){ try{ const r=await jget('/api/products/barcode/'+encodeURIComponent(v)+'?tenantId='+TENANT); if(r.data) p=r.data; }catch(e){} }
  if(p) addToCart(p); else alert('غير موجود: '+v);
  const si=document.getElementById('searchInput'); if(si) si.value=''; const sc=document.getElementById('scanInput'); if(sc) sc.value='';
}
function chg(i,delta){ cart[i].qty=Math.max(1,cart[i].qty+delta); renderCart(); renderGrid(); }
function renderCart(){
  // new bill panel
  const wrap=document.getElementById('billItems');
  let sub=0,tax=0;
  if(wrap){
    wrap.innerHTML='';
    cart.forEach((c,i)=>{
      const line=c.price*c.qty; const t=line*c.tax; sub+=line; tax+=t;
      const row=document.createElement('div'); row.className='bitem';
      row.innerHTML='<img src="'+(c.img||'')+'"/><div style="flex:1"><div style="font-weight:700">'+c.name+'</div><div class="muted" style="font-size:.75rem">Rs.'+c.price.toFixed(2)+'</div></div><div class="qty"><button onclick="chg('+i+',-1)">−</button><span>'+c.qty+'</span><button onclick="chg('+i+',1)">+</button></div><a href="#" onclick="event.preventDefault();cart.splice('+i+',1);renderCart();renderGrid()" style="color:#DC2626;font-size:.75rem">Remove</a>';
      wrap.appendChild(row);
    });
  } else {
    cart.forEach(c=>{ const line=c.price*c.qty; const t=line*c.tax; sub+=line; tax+=t; });
  }
  // legacy hidden table for compat
  const tb=document.getElementById('cartBody'); if(tb){ tb.innerHTML=''; cart.forEach((c,i)=>{ const tr=document.createElement('tr'); tr.innerHTML='<td>'+c.name+'</td><td>'+c.qty+'</td><td>'+c.price.toFixed(2)+'</td>'; tb.appendChild(tr);});}
  const disc=Number(document.getElementById('discountTotal').value||0);
  const billSub=document.getElementById('billSub'); if(billSub) billSub.textContent='Rs.'+sub.toFixed(2);
  const billTax=document.getElementById('billTax'); if(billTax) billTax.textContent='Rs.'+tax.toFixed(2);
  const grand=sub+tax-disc;
  const billTot=document.getElementById('billTotal'); if(billTot) billTot.textContent='Rs.'+grand.toFixed(2);
  const cs=document.getElementById('cartSubtotal'); if(cs) cs.textContent=sub.toFixed(2);
  const ct=document.getElementById('cartTax'); if(ct) ct.textContent=tax.toFixed(2);
  const gt2=document.getElementById('cartTotal'); if(gt2) gt2.textContent=grand.toFixed(2);
  const pay=document.getElementById('payAmount'); if(pay) pay.value=grand.toFixed(2);
  const br=document.getElementById('posBranch')?.value||''; const bbr=document.getElementById('billBranch'); if(bbr) bbr.textContent=br?br.slice(0,8)+'…':'—';
}
function clearCart(){ cart=[]; renderCart(); renderGrid(); document.getElementById('posOut').textContent=''; const r=document.getElementById('receipt'); if(r) r.style.display='none'; }
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
    cart=[]; renderCart(); renderGrid(); loadDash();
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
async function loadInventory(){const r=await jget('/api/reports/inventory?tenantId='+TENANT);const tb=document.getElementById('invBody');tb.innerHTML='';(r.data||[]).forEach(x=>{const tr=document.createElement('tr');tr.innerHTML='<td>'+(x.name||x.productId)+'</td><td>'+x.qty+'</td><td>'+x.status+'</td>';tb.appendChild(tr)})}
async function adjustInv(){const body={tenantId:TENANT,branchId:document.getElementById('invBranch').value||document.getElementById('posBranch').value,productId:document.getElementById('invProduct').value,qtyDelta:Number(document.getElementById('invQty').value),type:'adjust'};await fetch('/api/inventory/movements',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(body)}).then(r=>r.json()).then(j=>alert(JSON.stringify(j)));loadInventory()}
async function transferInv(){const body={tenantId:TENANT,fromBranchId:document.getElementById('trFrom').value,toBranchId:document.getElementById('trTo').value,lines:[{productId:document.getElementById('trProd').value,qty:Number(document.getElementById('trQty').value)}]};await fetch('/api/inventory/transfer',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(body)}).then(r=>r.json()).then(j=>alert(JSON.stringify(j)));loadInventory()}
async function loadCustomers(){const r=await jget('/api/customers?tenantId='+TENANT);const tb=document.getElementById('custBody');tb.innerHTML='';(r.data||[]).forEach(c=>{const tr=document.createElement('tr');tr.innerHTML='<td>'+c.name+'</td><td>'+(c.phone||'')+'</td><td>'+(c.balance??0)+'</td><td>'+(c.creditLimit||c.credit_limit||0)+'</td>';tb.appendChild(tr)})}
async function createCustomer(){const body={tenantId:TENANT,name:document.getElementById('cName').value,phone:document.getElementById('cPhone').value,creditLimit:Number(document.getElementById('cLimit').value||0)};await fetch('/api/customers',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(body)}).then(r=>r.json()).then(j=>alert(JSON.stringify(j)));loadCustomers()}
async function payCustomer(){const id=document.getElementById('payCustId').value;const amt=Number(document.getElementById('payAmt').value);await fetch('/api/customers/'+id+'/pay',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({amount:amt})}).then(r=>r.json()).then(j=>alert(JSON.stringify(j)));loadCustomers()}
async function loadPurchases(){const r=await jget('/api/purchases?tenantId='+TENANT);const tb=document.getElementById('purBody');tb.innerHTML='';(r.data||[]).forEach(p=>{const tr=document.createElement('tr');tr.innerHTML='<td>'+(p.supplierId||'')+'</td><td>'+(p.grandTotal||p.grand_total||0)+'</td><td>'+p.status+' <button onclick="receivePur(\''+p.id+'\')">استلام</button></td>';tb.appendChild(tr)})}
async function receivePur(id){await fetch('/api/purchases/'+id+'/receive',{method:'POST'}).then(r=>r.json()).then(j=>alert(JSON.stringify(j)));loadPurchases()}
async function createPurchase(){let sup=document.getElementById('purSup').value;if(!sup){const s=await jget('/api/suppliers?tenantId='+TENANT);if(s.data&&s.data[0]) sup=s.data[0].id; else {const ns=await fetch('/api/suppliers',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({tenantId:TENANT,name:'مورد تجريبي',phone:'000'})}).then(r=>r.json()); sup=ns.data.id} document.getElementById('purSup').value=sup;}const br=document.getElementById('posBranch').value||(await jget('/api/branches?tenantId='+TENANT)).data?.[0]?.id;const body={tenantId:TENANT,branchId:br,supplierId:sup,lines:[{productId:document.getElementById('purProd').value,qty:Number(document.getElementById('purQty').value),cost:Number(document.getElementById('purCost').value||0)}]};await fetch('/api/purchases',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(body)}).then(r=>r.json()).then(j=>alert(JSON.stringify(j)));loadPurchases()}
async function loadReports(){const from=new Date(Date.now()-7*86400000).toISOString(),to=new Date().toISOString();const p=await jget('/api/reports/profit?tenantId='+TENANT+'&from='+from+'&to='+to);const top=await jget('/api/reports/top-products?tenantId='+TENANT+'&from='+from+'&to='+to);document.getElementById('reportsOut').innerHTML='<b>ربح 7 أيام:</b> إيراد '+(p.data?.revenue||0)+' تكلفة '+(p.data?.cost||0)+' ربح '+(p.data?.profit||0)+' هامش '+(p.data?.margin||0).toFixed(1)+' %<br><b>الأكثر مبيعا:</b> '+JSON.stringify(top.data||[])}
loadDash(); loadProducts(); loadBranches();
