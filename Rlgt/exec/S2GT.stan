// Dual Seasonal Global Trend (SGT) algorithm

data {  
	int<lower=2> SEASONALITY;
	int<lower=2> SEASONALITY2;
	real<lower=0> CAUCHY_SD;
	real MIN_POW_TREND;  real MAX_POW_TREND;
	real<lower=0> MIN_SIGMA;
	real<lower=1> MIN_NU; real<lower=1> MAX_NU;
	int<lower=1> N;
	vector<lower=0>[N] y;
	real<lower=0> POW_TREND_ALPHA; real<lower=0> POW_TREND_BETA; 
	real<lower=0> POW_SIGMA_ALPHA; real<lower=0> POW_SIGMA_BETA; 
}
parameters {
	real<lower=MIN_NU,upper=MAX_NU> nu; 
	real<lower=0> sigma;
	real <lower=0,upper=1>levSm;
	real <lower=0,upper=1>sSm;
	real <lower=0,upper=1>s2Sm;
	real <lower=0,upper=1>powx;
	real <lower=0,upper=1> powTrendBeta;
	real coefTrend;
	real <lower=MIN_SIGMA> offsetSigma;
	vector[SEASONALITY] initSu; //unnormalized
	vector[SEASONALITY2] initSu2; //unnormalized
} 
transformed parameters {
	real <lower=MIN_POW_TREND,upper=MAX_POW_TREND>powTrend;
	vector<lower=0>[N] l;
	vector<lower=0>[N+SEASONALITY] s;
	vector<lower=0>[N+SEASONALITY2] s2;
	real sumsu;
	
	sumsu = 0;
	for (i in 1:SEASONALITY) 
		sumsu = sumsu+ initSu[i];
	for (i in 1:SEASONALITY) 
		s[i] = initSu[i]*SEASONALITY/sumsu;
	s[SEASONALITY+1] = s[1];
	
	sumsu = 0;
	for (i in 1:SEASONALITY2) 
		sumsu = sumsu+ initSu2[i];
	for (i in 1:SEASONALITY2) 
		s2[i] = initSu2[i]*SEASONALITY2/sumsu;
	s2[SEASONALITY+1] = s2[1];
	
	l[1] = y[1]/(s[1]*s2[1]);
	powTrend= (MAX_POW_TREND-MIN_POW_TREND)*powTrendBeta+MIN_POW_TREND;
	
	for (t in 2:N) {
		l[t]  = levSm*y[t]/(s[t]*s2[t]) + (1-levSm)*l[t-1] ;  
		s[t+SEASONALITY] = sSm*y[t]/(l[t]*s2[t])+(1-sSm)*s[t];
		s2[t+SEASONALITY2] = s2Sm*y[t]/(l[t]*s[t])+(1-s2Sm)*s2[t];
	}
}
model {
	real expVal;

	sigma ~ cauchy(0,CAUCHY_SD) T[0,];
	offsetSigma ~ cauchy(MIN_SIGMA,CAUCHY_SD) T[MIN_SIGMA,];	
	coefTrend ~ cauchy(0, CAUCHY_SD);
	powTrendBeta ~ beta(POW_TREND_ALPHA, POW_TREND_BETA);
	powx ~ beta(POW_SIGMA_ALPHA, POW_SIGMA_BETA);

	for (t in 1:SEASONALITY)
		initSu[t] ~ cauchy (1, 0.3) T[0.01,];
	for (t in 1:SEASONALITY2)
		initSu2[t] ~ cauchy (1, 0.3) T[0.01,];
	
	for (t in 2:N) {
	  expVal = (l[t-1]+ coefTrend*l[t-1]^powTrend)*s[t]*s2[t];
	  y[t] ~ student_t(nu, expVal, sigma*expVal^powx+ offsetSigma);
	}
}
