// Generalized Seasonality, Global Trend (gSGT) algorithm

data {  
	int<lower=2> SEASONALITY;
	real<lower=0> CAUCHY_SD;
	real MIN_POW_TREND;  real MAX_POW_TREND;
	real<lower=0> MIN_SIGMA;
	real<lower=1> MIN_NU; real<lower=1> MAX_NU;
	real<lower=0> POW_TREND_ALPHA; real<lower=0> POW_TREND_BETA;
	real<lower=0> POW_SEASON_ALPHA; real<lower=0> POW_SEASON_BETA;
	int<lower=1> N;
	vector<lower=0>[N] y; 
}
parameters {
	real<lower=MIN_NU,upper=MAX_NU> nu; 
	real <lower=0,upper=1> levSm;
	
	real <lower=0,upper=1> sSm;
	real <lower=0,upper=1> powSeason;
	vector<lower=0>[SEASONALITY] initSu; 
	
	real globTrend;
	real <lower=0,upper=1> globTrendPowBeta;

	real<lower=0> sigma;
	real <lower=0,upper=1> powSigma;
	real <lower=MIN_SIGMA> offsetSigma; 
} 
transformed parameters {
  vector<lower=0>[N] l;
  vector<lower=0>[N+SEASONALITY] s;
  real <lower=MIN_TREND_POW,upper=MAX_TREND_POW> globTrendPow;
  
  for (i in 1:SEASONALITY) 
    s[i] = initSu[i];
  s[SEASONALITY+1] = s[1];
  
  l[1] = y[1];
  globTrendPow= (MAX_POW_TREND-MIN_POW_TREND)*globTrendPowBeta+MIN_POW_TREND;
  for (t in 2:N) {
    l[t]  = levSm*(y[t] - s[t]*l[t-1]^powSeason) + (1-levSm)*l[t-1] ;
    s[t+SEASONALITY]= sSm*(y[t]-l[t-1]- globTrend*l[t-1]^globTrendPow)/l[t-1]^powSeason + (1-sSm)*s[t]; 
  }
}
model {
  real expVal;
  
  levSm ~ beta(2,1);
  powSeason ~ beta(POW_SEASON_ALPHA, POW_SEASON_BETA);
  globTrendPowBeta ~ beta(POW_TREND_ALPHA, POW_TREND_BETA);
  sigma ~ cauchy(0,CAUCHY_SD) T[0,];
  offsetSigma ~ cauchy(MIN_SIGMA,CAUCHY_SD) T[MIN_SIGMA,];
  globTrend ~ cauchy(0, CAUCHY_SD);
  
  for (t in 1:SEASONALITY) 
    initSu[t] ~ cauchy (0, y[t]*0.01);
  
  for (t in 2:N) {
    expVal = l[t-1] + globTrend*l[t-1]^globTrendPow + s[t]*l[t-1]^powSeason;
    y[t] ~ student_t(nu, expVal, sigma*l[t-1]^powSigma + offsetSigma);
  }
}
