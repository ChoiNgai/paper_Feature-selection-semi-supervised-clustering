function [V_pc,V_pe,Vxb] = SMUCclust(data, cluster_n,data_label)%data_label是30*14维，包括标签,data_label0是30*13维，不包括标签
data_n = size(data, 1); % 求出data的第一维(rows)数,即样本个数
in_n = size(data, 2);   % 求出data的第二维(columns)数，即特征值长度
% 默认操作参数
data = double(data);
data_label = double(data_label);
options = [2; % 隶属度矩阵U的指数
   1000;                % 最大迭代次数
   1e-5;               % 隶属度最小变化量,迭代终止条件
   1];                 % 每次迭代是否输出信息标志

%将options 中的分量分别赋值给四个变量;
expo = options(1);          % 隶属度矩阵U的指数
max_iter = options(2);  % 最大迭代次数
min_impro = options(3);  % 隶属度最小变化量,迭代终止条件
display = options(4);  % 每次迭代是否输出信息标志
lamda=0.3;
center_count = zeros(max_iter, 1); % 初始化输出参数obj_fcn
%初始化center,F
[center0,F] = initcenter(data_label,data,cluster_n);
% 初始化模糊分配矩阵,使U满足列上相加为1,cluster_n=2,用户填上去的种类数c=cluster_n
a=5;%5比6好
U = initfcm(cluster_n, data,center0,F,a,expo); %首个U，center0不用于判断
label_number=size(data_label,1);
label_number
% Main loop  主要循环
for i = 1:max_iter
       [U, center] = stepfcm(data, U, cluster_n, expo,a,F,label_number,lamda);
       center_count(i)=norm(center);%求模norm
   if display
      fprintf('SMUC:Iteration count = %d\n', i);
   end
% 终止条件判别
   if i>1
     if abs(center_count(i) - center_count(i-1)) < min_impro
           break;
     end
   end
end

iter_n = i; % 实际迭代次数
%obj_fcn(iter_n+1:max_iter) = [];
[V_pc,~,V_pe,Vxb] = V_pcpexb(U,data,center);
Vpe_log = U.*log(U);
[i,j] = find(Vpe_log);
Vpe_log(i,j) = 0;
V_pe = -sum(sum(Vpe_log))/cluster_n;
end


function [center,F] = initcenter(data_label,data,cluster_n)%默认为分3类
center=zeros(cluster_n,size(data, 2));%可能要改
F=zeros(cluster_n,size(data, 1));%可能要改
for k=1:cluster_n
 for i=1:size(data_label,1)%center第一行，第一类
   if data_label(i,1)==k
       F(k,i)=1;
       for j=2:size(data_label,2)-1
          center(k,j)=(data_label(i,j)+center(k,j))/i;
       end
   end
 end
end
  
end


% 子函数
function U = initfcm(cluster_n,data,center0,F,a,expo)%a=6
% 初始化fcm的隶属度函数矩阵
% 输入:
%   cluster_n   ---- 聚类中心个数
%   data_n      ---- 样本点数
% 输出：
%   U           ---- 初始化的隶属度矩阵
% U = rand(cluster_n, data_n);
% col_sum = sum(U);                      
% U = U./col_sum(ones(cluster_n, 1), :);%归一化
dist = distfcm(center0, data); 
tmp = dist.^(-2/(expo-1)); 
%U= tmp./(ones(cluster_n, 1)*sum(tmp));
U_fcm= tmp./(ones(cluster_n, 1)*sum(tmp));
U_3 =(a/(1+a))* U_fcm.*(ones(cluster_n,1)*sum(F));
U=U_fcm+(a/(1+a))*F-U_3;
end


% 子函数
function [U_new, center] = stepfcm(data,U,cluster_n, expo,a,F,label_number,lamda)
% 模糊C均值聚类时迭代的一步
% 输入：
%   data        ---- nxm矩阵,表示n个样本,每个样本具有m的维特征值
%   U           ---- 隶属度矩阵
%   cluster_n   ---- 标量,表示聚合中心数目,即类别数
%   expo        ---- 隶属度矩阵U的指数                     
% 输出：
%   U_new       ---- 迭代计算出的新的隶属度矩阵
%   center      ---- 迭代计算出的新的聚类中心
%   obj_fcn     ---- 目标函数值
[j,i] = size(data);

% mf = U.^expo; % 隶属度矩阵进行指数运算结果
%计算center改变U
% mf_ss=[mf(:,1:label_number)*a^expo,mf(:,(label_number+1):size(data, 1))];%使U前30列乘上a
% center = mf_ss*data./((ones(size(data, 2), 1)*sum(mf_ss'))'); % 新聚类中心(7)式
center = U*data./(sum(U,2)*ones(1,size(data,2)));
dist = distfcm(center, data);        %    计算距离
% tmp = dist.^(-2/(expo-1));  %加权指数幂运算（加上聚类计算就是u_ij）  
% U_fcm= tmp./(ones(cluster_n, 1)*sum(tmp));
% U_3 =(a/(1+a))* U_fcm.*((ones(cluster_n,1)*sum(F)));
% U_new=U_fcm+(a/(1+a))*F-U_3;

U_new=(ones(cluster_n, 1)*(1-sum(F))).*exp(-distfcm(center, data)./lamda)./(ones(cluster_n, 1)*sum(exp(-distfcm(center, data)./lamda)))+F;

%A0 = 1/i * sum(sum(F)).*( data(1:j,:)- sum(F)'*ones(1,i) .*data(1:j,:)./sum(sum(F)) ).*(data(1:j,:)- sum(F)'.*data(1:j,:)./sum(sum(F)) ) ;
%A = 1./(A0.^expo);


%center = U_new*data./(sum(U_new,2)*ones(1,size(data,2)));

end


% 子函数
function out = distfcm(center, data)
% 计算样本点距离聚类中心的距离
% 输入：
%   center     ---- 聚类中心
%   data       ---- 样本点
% 输出：
%   out        ---- 距离
out = zeros(size(center, 1), size(data, 1));
 for k = 1:size(center, 1) % 对每一个聚类中心
   % 每一次循环求得所有样本点到一个聚类中心的距离
   out(k, :) = sqrt(sum(((data-ones(size(data,1),1)*center(k,:)).^2)',1));
 end
end


