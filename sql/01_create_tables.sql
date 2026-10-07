BEGIN;

CREATE TABLE public.items (
    item_code INTEGER PRIMARY KEY,
    item TEXT NOT NULL,
    unit TEXT NOT NULL,
    item_group TEXT,
    item_category TEXT
);

CREATE TABLE public.premises (
    premise_code INTEGER PRIMARY KEY,
    premise TEXT,
    state TEXT,
    district TEXT,
    premise_type TEXT,
    premise_type_clean TEXT,
    lookup_missing BOOLEAN NOT NULL
);

CREATE TABLE public.price_observations (
    date DATE NOT NULL,
    premise_code INTEGER NOT NULL,
    item_code INTEGER NOT NULL,
    price NUMERIC NOT NULL CHECK (price > 0),

    source_month TEXT NOT NULL,
    is_supporting_period BOOLEAN NOT NULL,

    item_month_median NUMERIC NOT NULL
        CHECK (item_month_median > 0),
    price_to_median DOUBLE PRECISION NOT NULL,

    flag_low_price BOOLEAN NOT NULL,
    flag_high_price BOOLEAN NOT NULL,
    flag_extreme_price BOOLEAN NOT NULL,

    item_lookup_missing BOOLEAN NOT NULL,
    premise_lookup_missing BOOLEAN NOT NULL,

    PRIMARY KEY (date, premise_code, item_code),

    FOREIGN KEY (item_code)
        REFERENCES public.items (item_code),

    FOREIGN KEY (premise_code)
        REFERENCES public.premises (premise_code),

    CHECK (
        flag_extreme_price = (flag_low_price OR flag_high_price)
    )
);

COMMIT;