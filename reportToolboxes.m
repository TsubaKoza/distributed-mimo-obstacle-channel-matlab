function info = reportToolboxes()
%REPORTTOOLBOXES Print installed MATLAB products; simulator needs base MATLAB only.
products=ver;
fprintf('MATLABリリース: %s\n',version);
fprintf('インストール済み製品:\n');
for i=1:numel(products)
    fprintf('  %s %s\n',products(i).Name,products(i).Version);
end
fprintf('このシミュレータの必須製品: base MATLABのみ。\n');
info=products;
end
