function f=recover_ols(x)

global infection_data date b c d

x=abs(x);

infection_gen=zeros(1,length(date));
infection_gen(1)=infection_data(1);

infection_current=zeros(1,length(date));
recover_stock=zeros(1,length(date));

recover_stock(1)=x;
infection_current(1)=infection_gen(1)-x;

s=zeros(1,length(date));
s(1)=1-infection_gen(1);

for i=2:length(date)
    infection_current(i)=infection_current(i-1)*(1+b(i-1)*s(i-1)-c);
    infection_gen(i)=infection_gen(i-1)+infection_current(i-1)*(b(i-1)*s(i-1));
    s(i)=s(i-1)-infection_current(i-1)*(b(i-1)*s(i-1))-d(i-1);
end

dev=infection_gen./infection_data-1;

f=dev*dev';