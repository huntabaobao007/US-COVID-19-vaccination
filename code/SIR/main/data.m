clc;
clear;

%% data input

[labor_temp,~,~]=xlsread('SIR_07Mar.xlsx');  
[state,state_name,~]=xlsread('state.xlsx');
state_name=state_name(:,2);

region=51;

pop=zeros(region,1);
date=1:length(labor_temp)/region;

Pfizer_w=0.4775;
Moderna_w=0.5225;

Pfizer_e1=0.52;
Moderna_e1=0.921;
Pfizer_e2=0.946;
Moderna_e2=0.941;

shooting=1;  % we adopt the efficiency of 1st or 2nd dose

if shooting==1
    Pfizer_e=Pfizer_e1;
    Moderna_e=Moderna_e1;
end
if shooting==2
    Pfizer_e=Pfizer_e2;
    Moderna_e=Moderna_e2;
end

eff=Pfizer_w*Pfizer_e+Moderna_w*Moderna_e;

i_stock=zeros(region,length(date));
r_stock=zeros(region,length(date));
d_stock=zeros(region,length(date));
v1_stock=zeros(region,length(date));
v2_stock=zeros(region,length(date));
policy=zeros(region,length(date));

for i=1:length(labor_temp)
    row=find(state==labor_temp(i,1));
    column=find(date+41==labor_temp(i,2));
    i_stock(row,column)=labor_temp(i,5);
    r_stock(row,column)=labor_temp(i,6);
    d_stock(row,column)=labor_temp(i,4);
    policy(row,column)=labor_temp(i,3);
    v1_stock(row,column)=labor_temp(i,7)*pop(row)/100;
    v2_stock(row,column)=labor_temp(i,8)/100*pop(row);
    pop(row)=labor_temp(i,10);
end

v1_stock(isnan(v1_stock))=0;
v2_stock(isnan(v2_stock))=0;

valid_r=~isnan(r_stock(:,length(date)));      % use states with valid recover data
valid_r(16)=0;              % IA with greater accumulative recover than infected 

i_current=nan(region,length(date));
i_current_ratio=nan(region,length(date));
r_stock_ratio=nan(region,length(date));
d_stock_ratio=nan(region,length(date));
for i=1:region
    if valid_r(i)
        i_current(i,:)=i_stock(i,:)-r_stock(i,:)-d_stock(i,:);
        i_current_ratio(i,:)=i_current(i,:)/pop(i);
        r_stock_ratio(i,:)=r_stock(i,:)/pop(i);
        d_stock_ratio(i,:)=d_stock(i,:)/pop(i);
    end
end

s_current=zeros(region,length(date));              % S group calculated by total population minus accumulated positive
s_current_adj1=zeros(region,length(date));         % S group after deducting 1st vaccine
s_current_adj2=zeros(region,length(date));         % S group after deducting 2nd vaccine
for i=1:region
    s_current(i,:)=pop(i)-i_stock(i,:);
end
s_current_adj1=(s_current-eff*v1_stock)./pop;
s_current_adj2=(s_current-eff*v2_stock)./pop;

%% estimate gamma using data in valid states

gamma=nan(region,length(date));

for i=1:region
    for j=2:length(date)
        gamma(i,j)=(r_stock_ratio(i,j)-r_stock_ratio(i,j-1)+d_stock_ratio(i,j)-d_stock_ratio(i,j-1))/i_current_ratio(i,j-1);
    end
end

gamma(~isnan(gamma))=max(0,gamma(~isnan(gamma)));
gamma(~isnan(gamma))=min(1,gamma(~isnan(gamma)));

gamma_mean=nan(region,1);
for i=1:region
    gamma_mean(i)=mean(gamma(i,:),'omitnan');
end
gamma_est_median=median(gamma_mean,'omitnan');
gamma_mean(isnan(gamma_mean))=gamma_est_median;  % heterogeneity in gamma

% boxplot for gamma

figure;
hold on
boxplot(-log(gamma_mean(valid_r)));
title('Boxplot for -ln\gamma_i')
text(1,6,'MD');
text(1,4,'KY');

%% estimate time variant beta using data in valid states

% I_t+1/I_t - 1 = beta_t * S_t - gamma
% beta_t = cons + theta * stringency_t + region_fixed + time_fixed
% rearrange into panel data form to use Stata to do the next regression
 
infection_g=nan(region,length(date)-1);
y1=nan(region,length(date)-1);
y2=nan(region,length(date)-1);
for i=1:length(date)-1
    infection_g(:,i)=i_current_ratio(:,i+1)./i_current_ratio(:,i)-1;
    y1(:,i)=(infection_g(:,i)+gamma_mean)./s_current_adj1(:,i);
    y2(:,i)=(infection_g(:,i)+gamma_mean)./s_current_adj2(:,i);
end

y1=y1';
y1(isnan(y1))=[];
y1=y1';
y1=max(0,y1);

y2=y2';
y2(isnan(y2))=[];
y2=y2';
y2=max(0,y2);

policy_stata=policy;
for i=region:-1:1
    if valid_r(i)==0
        policy_stata(i,:)=nan(1,length(date));
    end
end
policy_stata(:,length(date))=[];
policy_stata=policy_stata';
policy_stata(isnan(policy_stata))=[];
policy_stata=policy_stata';

raw_data=nan(sum(valid_r)*(length(date)-1),4);
raw_data(:,1)=kron(state(valid_r),ones(length(date)-1,1));
raw_data(:,2)=kron(ones(sum(valid_r),1),(1:length(date)-1)');
raw_data(:,3)=y1;
raw_data(:,4)=policy_stata;

xlswrite('panel.xlsx',raw_data);

%  Then go to "beta.do" file to run Stata panel regression and get the
%  results

%% input theta

[~,~,theta_temp]=xlsread('beta_gen.xlsx');

for i=1:length(theta_temp)
    if ischar(theta_temp{i,2})
    theta_temp{i,2}=erase(theta_temp{i,2},"*");
    theta_temp{i,2}=str2num(theta_temp{i,2});
    end
end

region_fixed=zeros(sum(valid_r),1);
time_fixed=zeros(length(date)-1,1);

for i=2:sum(valid_r)
    region_fixed(i)=theta_temp{2*i+2,2};
end
for i=2:length(date)-1
    time_fixed(i)=theta_temp{2*i+58,2};
end
theta=theta_temp{4,2};
cons=theta_temp{100,2};

region_fixed_median=median(region_fixed,'omitnan');
time_fixed_median=median(time_fixed,'omitnan');

%%  estimate vaccine rate delta

% delta=cons + region_fixed + time_fixed

delta1=zeros(region,length(date));
delta2=zeros(region,length(date));

for i=14:length(date)
    delta1(:,i)=(v1_stock(:,i)-v1_stock(:,i-1))./pop;
    delta2(:,i)=(v2_stock(:,i)-v2_stock(:,i-1))./pop;
end

delta1_data=delta1(:,14:length(date));
delta1_data=delta1_data';
delta1_data=reshape(delta1_data,[],1);

delta2_data=delta2(:,14:length(date));
delta2_data=delta2_data';
delta2_data=reshape(delta2_data,[],1);

delta_stata=zeros(region*(length(date)-13),1);
delta_stata(:,1)=kron(state,ones(length(date)-13,1));
delta_stata(:,2)=kron(ones(region,1),(1:length(date)-13)');
delta_stata(:,3)=delta1_data;
delta_stata(:,4)=delta2_data;

xlswrite('delta.xlsx',delta_stata);

% then go to stata to run the "delta.do" file to get panel regression
% results

%% input delta

[~,~,delta_temp]=xlsread('delta_gen.xlsx');

for i=1:length(delta_temp)
    if ischar(delta_temp{i,2})
    delta_temp{i,2}=erase(delta_temp{i,2},"*");
    delta_temp{i,2}=str2num(delta_temp{i,2});
    end
end
delta_reg=cell2mat(delta_temp(4:2:118,2));

delta_median=median(delta_reg(1:50));
region_fixed_v=[0;delta_reg(1:50)];

time_fixed_v=[0;delta_reg(51:57)];
cons_v=delta_reg(58);

time_fixed_v_median=median(time_fixed_v);

delta=zeros(region,length(date));
for i=14:length(date)
    delta(:,i)=cons_v+region_fixed_v+time_fixed_v(i-13);
end

save('delta.mat','cons_v','region_fixed_v','time_fixed_v','time_fixed_v_median','date','pop');

%% find the best fitted recover for invalid states

global infection_data date b c d

gamma_est=gamma_est_median;
region_est=region_fixed_median;

i_stock_ratio=zeros(region,length(date));
for i=1:region
    i_stock_ratio(i,:)=i_stock(i,:)/pop(i);
end

valid_r_index=zeros(region,1);
valid_r_index(1)=valid_r(1);
for i=2:region
    valid_r_index(i)=valid_r_index(i-1)+valid_r(i);
end

i_current_gen=zeros(region,length(date));

for i=1:region
    if ~valid_r(i)
        b=max(0,cons+theta*policy(i,:)+region_est+[time_fixed' 0]);
        c=gamma_mean(i);
        d=eff*delta(i,:);
        infection_data=i_stock_ratio(i,:);
        i_current_gen(i,1)=i_stock_ratio(i,1)-fminsearch(@recover_ols,0);
    else
        i_current_gen(i,1)=i_stock_ratio(i,1)-r_stock_ratio(i,1)-d_stock_ratio(i,1);
    end
end
    
%% simulate for whole process

beta=zeros(region,length(date));

for i=1:region
    for k=1:length(date)-1
        if ~valid_r(i)
            beta(i,k)=max(0,cons+theta*policy(i,k)+region_est+time_fixed(k));
        else
            beta(i,k)=max(0,cons+theta*policy(i,k)+region_fixed(valid_r_index(i))+time_fixed(k));
        end
    end
end

i_stock_gen=zeros(region,length(date));
s_current_gen=zeros(region,length(date));

i_stock_gen(:,1)=i_stock_ratio(:,1);
s_current_gen(:,1)=1-i_stock_gen(:,1);

i_current_gen_nov=i_current_gen;
i_stock_gen_nov=i_stock_gen;
s_current_gen_nov=s_current_gen;

for i=2:length(date)
    i_current_gen(:,i)=i_current_gen(:,i-1).*(1+beta(:,i-1).*s_current_gen(:,i-1)-gamma_mean);
    i_stock_gen(:,i)=i_current_gen(:,i).*beta(:,i-1).*s_current_gen(:,i-1)+i_stock_gen(:,i-1);
    s_current_gen(:,i)=s_current_gen(:,i-1)-i_current_gen(:,i).*beta(:,i-1).*s_current_gen(:,i-1)-eff*delta(:,i-1);
    
    i_current_gen_nov(:,i)=i_current_gen_nov(:,i-1).*(1+beta(:,i-1).*s_current_gen_nov(:,i-1)-gamma_mean);
    i_stock_gen_nov(:,i)=i_current_gen_nov(:,i).*beta(:,i-1).*s_current_gen_nov(:,i-1)+i_stock_gen_nov(:,i-1);
    s_current_gen_nov(:,i)=s_current_gen_nov(:,i-1)-i_current_gen_nov(:,i).*beta(:,i-1).*s_current_gen_nov(:,i-1);
end

save('dynamics.mat','i_current_gen','i_stock_gen','s_current_gen');

% generate correlation between model and data
r_state=zeros(region,1);
for i=1:region
    r_state(i)=(min(min(corrcoef(i_stock_ratio(i,1:21),i_stock_gen(i,1:21)))));
end

%% graph

t_start=datetime([2020,10,12]);
t_series=dateshift(t_start,'dayofweek',2,1:200);
t_series_str=datestr(t_series,'ddmmmyy');

figure;
for i=1:region
    subplot(9,6,i);
    hold on;
    plot(i_stock_ratio(i,1:21),'-k','LineWidth',2);
    plot(i_stock_gen(i,1:21),'-.r','LineWidth',2);
    title(state_name{i});
    ylim=get(gca,'ylim');
    ylim(1)=0;
    set(gca,'ylim',ylim);
    tick_series=[1,21];
    set(gca,'xtick',tick_series,'xticklabel',t_series_str(tick_series,:));
end
a=suptitle('b');
set(a,'Position',[0.12 -0.1 0],'Fontsize',25);

%% prediction from beginning 

T=200;

period=length(date)+T;

i_current_gen=[i_current_gen zeros(region,T)];
i_stock_gen=[i_stock_gen zeros(region,T)];
s_current_gen=[s_current_gen zeros(region,T)];

i_current_gen_nov=[i_current_gen_nov zeros(region,T)];
i_stock_gen_nov=[i_stock_gen_nov zeros(region,T)];
s_current_gen_nov=[s_current_gen_nov zeros(region,T)];

beta=[beta zeros(region,period-length(date))];

for i=1:region
    for k=length(date):period
        if ~valid_r(i)
            beta(i,k)=max(0,cons+theta*policy(i,length(date))+region_est+time_fixed_median);
        else
            beta(i,k)=max(0,cons+theta*policy(i,length(date))+region_fixed(valid_r_index(i))+time_fixed_median);
        end
    end
end

save('beta.mat','beta','gamma_mean');

delta=[delta zeros(region,period-length(date))];
for i=length(date)+1:period
    delta(:,i)=cons_v+region_fixed_v+time_fixed_v_median;
end

vaccine=zeros(region,period);
for i=2:length(date)
    vaccine(:,i)=vaccine(:,i-1)+delta(:,i);
end
for i=length(date)+1:period
    for k=1:region
        if vaccine(k,i-1)+delta(k,i)<s_current_gen(k,12)
            vaccine(k,i)=vaccine(k,i-1)+delta(k,i);
        else
            vaccine(k,i)=s_current_gen(k,12);
            delta(k,i)=s_current_gen(k,12)-vaccine(k,i-1);
        end
    end
    
    i_current_gen(:,i)=i_current_gen(:,i-1).*(1+beta(:,i-1).*s_current_gen(:,i-1)-gamma_mean);
    i_stock_gen(:,i)=i_current_gen(:,i).*beta(:,i-1).*s_current_gen(:,i-1)+i_stock_gen(:,i-1);
    s_current_gen(:,i)=max(0,s_current_gen(:,i-1)-i_current_gen(:,i).*beta(:,i-1).*s_current_gen(:,i-1)-eff*delta(:,i-1));
    
    i_current_gen_nov(:,i)=i_current_gen_nov(:,i-1).*(1+beta(:,i-1).*s_current_gen_nov(:,i-1)-gamma_mean);
    i_stock_gen_nov(:,i)=i_current_gen_nov(:,i).*beta(:,i-1).*s_current_gen_nov(:,i-1)+i_stock_gen_nov(:,i-1);
    s_current_gen_nov(:,i)=s_current_gen_nov(:,i-1)-i_current_gen_nov(:,i).*beta(:,i-1).*s_current_gen_nov(:,i-1);
end

% calculate vaccine share

vaccine_share=pop'*vaccine/sum(pop);
vaccine_share(1:12)=nan(1,12);

%% figure of simulation

x=1:21;

i_stock_ratio_graph=[i_stock_ratio nan(region,period-length(date))];
g1=pop'*i_stock_gen(:,x)/sum(pop);
g4=pop'*i_stock_ratio_graph(:,x)/sum(pop);
r_square=corrcoef(g1,g4);

figure;
hold on;
h=plot(x,[g1;g4]);   
ylabel('Cumulative Infection');
set(h(1),'LineStyle','-.','Linewidth',2,'color','r');
set(h(2),'LineStyle','-','Linewidth',2,'color','k');
line([13 13],[0.05 0.09],'linewidth',1,'color','k','linestyle','--');
text(1,0.05,'Vaccination Begins');
xlim([1,length(x)]);
tick_series=1:5:21;
set(gca,'xtick',tick_series,'xticklabel',t_series_str(tick_series,:),'ylim',[0,0.12]);
legend([h(1),h(2)],{'Model Projections','Empirical Data'},'Location','Best');

title('a','Position',[-0.4,0.123],'FontSize',15);

%% figure of prediction

x=length(date):101;
i_stock_gen_nov_graph=i_stock_gen_nov;
i_stock_gen_nov_graph(:,1:12)=nan(region,12);

g1=pop'*i_stock_gen(:,x)/sum(pop);
g2=pop'*i_stock_gen_nov_graph(:,x)/sum(pop);

figure;
hold on;
h=plot(x,[g1;g2]);
set(gca,'xlim',[21 101],'xtick',21:20:101,'xticklabel',t_series_str(21:20:101,:));
ylabel('Cumulative Infection');
set(h(1),'LineStyle','-','Linewidth',2,'color','r');
set(h(2),'LineStyle','--','Linewidth',2,'color','r');
legend([h(1),h(2)],{'Projection with vaccines','Projection without vaccines',...
   },'Location','Best');
xlabel('Time');
