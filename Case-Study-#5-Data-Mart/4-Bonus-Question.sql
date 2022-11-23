/**
Which areas of the business have the highest negative impact in sales metrics performance in 2020 for the 12 week before and after period?

region
platform
age_band
demographic
customer_type
Do you have any further recommendations for Danny’s team at Data Mart or any interesting insights based off this analysis?
**/
select metrics, round(avg(pertcg),2) as avg_sales
from (
    select
        'region' as metrics, initcap(region) as value, before_effect,
        after_effect, after_effect - before_effect as change,
        round(((after_effect-before_effect)/before_effect::numeric)*100,2) as pertcg, '2018' as year_
    from (
        select
            region, sum(sales) filter(where week_dates < '2018-06-15'::date) as before_effect,
            sum(sales) filter(where week_dates >= '2018-06-15'::date) as after_effect
        from (
		    select week_dates, sales, region
		    from data_mart.clean_weekly_sales
            where week_dates between '2018-06-15'::date - interval '12 week'
            and '2018-06-15'::date + interval '11 week'
            order by 1
	    ) delta_weeks
        group by 1
    ) as before_after

    union all

    select
        'platform' as metrics, initcap(platform) as value, before_effect,
        after_effect, after_effect - before_effect as change,
        round(((after_effect-before_effect)/before_effect::numeric)*100,2) as pertcg, '2019' as year_
    from (
        select
            platform, sum(sales) filter(where week_dates < '2019-06-15'::date) as before_effect,
            sum(sales) filter(where week_dates >= '2019-06-15'::date) as after_effect
        from (
            select week_dates, sales, platform
            from data_mart.clean_weekly_sales
            where week_dates between '2019-06-15'::date - interval '12 week'
            and '2019-06-15'::date + interval '11 week'
            order by 1
        ) delta_weeks
        group by 1
    ) as before_after

    union all

    select
        'age_band' as metrics, initcap(age_band) as value,
        before_effect, after_effect, after_effect - before_effect as change,
        round(((after_effect-before_effect)/before_effect::numeric)*100,2) as pertcg, '2020' as year_
    from (
        select
            age_band, sum(sales) filter(where week_dates < '2020-06-15'::date) as before_effect,
            sum(sales) filter(where week_dates >= '2020-06-15'::date) as after_effect
        from (
            select week_dates, sales, age_band
            from data_mart.clean_weekly_sales
            where week_dates between '2020-06-15'::date - interval '12 week'
            and '2020-06-15'::date + interval '11 week'
            order by 1
        ) delta_weeks
        group by 1
    ) as before_after

    union all

    select
        'demographic' as metrics, initcap(demographic) as value,
        before_effect, after_effect, after_effect - before_effect as change,
        round(((after_effect-before_effect)/before_effect::numeric)*100,2) as pertcg, '2020' as year_
    from (
        select
            demographic, sum(sales) filter(where week_dates < '2020-06-15'::date) as before_effect,
            sum(sales) filter(where week_dates >= '2020-06-15'::date) as after_effect
        from (
            select week_dates, sales, demographic
            from data_mart.clean_weekly_sales
            where week_dates between '2020-06-15'::date - interval '12 week'
            and '2020-06-15'::date + interval '11 week'
            order by 1
        ) delta_weeks
        group by 1
    ) as before_after

    union all

    select
        'customer_type' as metrics, initcap(customer_type) as value,
        before_effect, after_effect, after_effect - before_effect as change,
        round(((after_effect-before_effect)/before_effect::numeric)*100,2) as pertcg, '2020' as year_
    from (
        select
            customer_type, sum(sales) filter(where week_dates < '2020-06-15'::date) as before_effect,
            sum(sales) filter(where week_dates >= '2020-06-15'::date) as after_effect
        from (
            select week_dates, sales, customer_type
            from data_mart.clean_weekly_sales
            where week_dates between '2020-06-15'::date - interval '12 week'
            and '2020-06-15'::date + interval '11 week'
            order by 1
        ) delta_weeks
        group by 1
    ) as before_after
) as tmp
group by 1
order by 2

/**
For the 2020, 12 week before and after period, region and platform have the highest negative sales metric performance impact.
**/