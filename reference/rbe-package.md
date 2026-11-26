# rbe: Rule-Based Ensembles

Fit RuleFit models for regression and classification, as described by
Friedman and Popescu (2008)
[doi:10.1214/07-AOAS148](https://doi.org/10.1214/07-AOAS148) . A boosted
tree ensemble creates a set of rules, and a regularized generalized
linear model from 'glmnet' is fit to the original predictors and binary
indicators for the rules. The rules can be made with 'xgboost' (Chen and
Guestrin (2016)
[doi:10.1145/2939672.2939785](https://doi.org/10.1145/2939672.2939785)
), 'lightgbm' (Ke et al. (2017)
<https://proceedings.neurips.cc/paper/2017/hash/6449f44a102fde848669bdd9eb6b76fa-Abstract.html>),
or 'catboost' (Prokhorenkova et al. (2018)
[doi:10.48550/arXiv.1706.09516](https://doi.org/10.48550/arXiv.1706.09516)
).

## See also

Useful links:

- <https://github.com/tidymodels/rbe>

- Report bugs at <https://github.com/tidymodels/rbe/issues>

## Author

**Maintainer**: Max Kuhn <max@posit.co>
([ORCID](https://orcid.org/0000-0003-2402-136X))

Authors:

- Max Kuhn <max@posit.co>
  ([ORCID](https://orcid.org/0000-0003-2402-136X))

Other contributors:

- Posit Software, PBC ([ROR](https://ror.org/03wc8by49)) \[copyright
  holder, funder\]
