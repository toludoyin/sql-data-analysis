/*
This technique is usually used when we inspect an important event and want to inspect the impact before and after a certain point in time.

Taking the week_date value of 2020-06-15 as the baseline week where the Data Mart sustainable packaging changes came into effect.

We would include all week_date values for 2020-06-15 as the start of the period after the change and the previous week_date values would be before

Using this analysis approach - answer the following questions:

1. What is the total sales for the 4 weeks before and after 2020-06-15? What is the growth or reduction rate in actual values and percentage of sales?
2. What about the entire 12 weeks before and after?
3. How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?
*/

-- 1.
select
    before_effect, after_effect, after_effect - before_effect as change,
    round(((after_effect-before_effect)/before_effect::numeric)*100,2) as pertcg
from (
    select
        sum(sales) filter(where week_dates < '2020-06-15'::date) as before_effect,
        sum(sales) filter(where week_dates >= '2020-06-15'::date) as after_effect
	from (
		select week_dates, sales
		from data_mart.clean_weekly_sales
        where week_dates between '2020-06-15'::date - interval '4 week'
        and '2020-06-15'::date + interval '3 week'
        order by 1
	) delta_weeks
) as before_after;

-- 2.
select
    before_effect, after_effect, after_effect - before_effect as change,
    round(((after_effect-before_effect)/before_effect::numeric)*100,2) as pertcg
from (
    select
        sum(sales) filter(where week_dates < '2020-06-15'::date) as before_effect,
        sum(sales) filter(where week_dates >= '2020-06-15'::date) as after_effect
	from (
		select week_dates,vsales from data_mart.clean_weekly_sales
        where week_dates between '2020-06-15'::date - interval '12 week'
        and '2020-06-15'::date + interval '11 week'
        order by 1
	) delta_weeks
) as before_after;

-- 3. for 4 weeks before and after
select
    before_effect, after_effect, after_effect - before_effect as change,
    round(((after_effect-before_effect)/before_effect::numeric)*100,2) as pertcg, '2018' as year_
from (
	select
        sum(sales) filter(where week_dates < '2018-06-15'::date) as before_effect,
        sum(sales) filter(where week_dates >= '2018-06-15'::date) as after_effect
	from (
		select week_dates, sales
		from data_mart.clean_weekly_sales
        where week_dates between '2018-06-15'::date - interval '4 week'
        and '2018-06-15'::date + interval '3 week'
        order by 1
	) delta_weeks
) as before_after

union all

select
    before_effect, after_effect, after_effect - before_effect as change,
    round(((after_effect-before_effect)/before_effect::numeric)*100,2) as pertcg, '2019' as year_
from (
	select
        sum(sales) filter(where week_dates < '2019-06-15'::date) as before_effect,
        sum(sales) filter(where week_dates >= '2019-06-15'::date) as after_effect
	from (
		select week_dates, sales
		from data_mart.clean_weekly_sales
        where week_dates between '2019-06-15'::date - interval '4 week'
        and '2019-06-15'::date + interval '3 week'
        order by 1
	) delta_weeks
) as before_after

union all

select
    before_effect, after_effect, after_effect - before_effect as change,
    round(((after_effect-before_effect)/before_effect::numeric)*100,2) as pertcg, '2020' as year_
from (
	select
        sum(sales) filter(where week_dates < '2020-06-15'::date) as before_effect,
        sum(sales) filter(where week_dates >= '2020-06-15'::date) as after_effect
	from (
		select week_dates, sales
		from data_mart.clean_weekly_sales
        where week_dates between '2020-06-15'::date - interval '4 week'
        and '2020-06-15'::date + interval '3 week'
        order by 1
	) delta_weeks
) as before_after;