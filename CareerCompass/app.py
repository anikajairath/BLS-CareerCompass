import streamlit as st
import pandas as pd

from retriever import retrieve
from engine import get_state_recommendations, get_msa_recommendations
from gemini import generate_answer


# ============================================================
# PAGE CONFIGURATION
# ============================================================

st.set_page_config(
    page_title="CareerCompass",
    page_icon="🧭",
    layout="wide"
)


# ============================================================
# CUSTOM CSS
# ============================================================

st.markdown(
    """
    <style>

    /* Main background */
    .stApp {
        background-color: #dff1ff;
    }

    /* Main content width */
    .block-container {
        padding-top: 2rem;
        padding-bottom: 3rem;
        max-width: 1200px;
    }

    /* Main title */
    .main-title {
        font-size: 3rem;
        font-weight: 800;
        color: #123b5d;
        text-align: center;
        margin-bottom: 0.2rem;
    }

    /* Subtitle */
    .subtitle {
        text-align: center;
        color: #41657d;
        font-size: 1.15rem;
        margin-bottom: 2rem;
    }

    /* Section headings */
    .section-title {
        color: #123b5d;
        font-size: 1.5rem;
        font-weight: 700;
        margin-top: 1rem;
        margin-bottom: 0.8rem;
    }

    /* Cards */
    .info-card {
        background-color: white;
        padding: 1.2rem;
        border-radius: 15px;
        border: 1px solid #c7e3f5;
        box-shadow: 0 3px 10px rgba(30, 80, 110, 0.08);
        margin-bottom: 1rem;
    }

    /* Occupation badge */
    .occupation-badge {
        background-color: #b9e2fa;
        color: #123b5d;
        padding: 0.5rem 0.9rem;
        border-radius: 20px;
        font-weight: 700;
        display: inline-block;
        margin-bottom: 1rem;
    }

    /* Small explanatory text */
    .small-text {
        color: #557487;
        font-size: 0.9rem;
    }

    /* Recommendation cards */
    .recommendation-card {
        background-color: white;
        padding: 1rem;
        border-radius: 12px;
        border-left: 5px solid #4da3d9;
        margin-bottom: 0.8rem;
        box-shadow: 0 2px 8px rgba(30, 80, 110, 0.07);
    }

    /* Footer */
    .footer {
        text-align: center;
        color: #557487;
        font-size: 0.85rem;
        margin-top: 3rem;
        padding-top: 1rem;
        border-top: 1px solid #b9d9eb;
    }

    </style>
    """,
    unsafe_allow_html=True
)


# ============================================================
# HEADER
# ============================================================

st.markdown(
    '<div class="main-title">🧭 CareerCompass</div>',
    unsafe_allow_html=True
)

st.markdown(
    """
    <div class="subtitle">
        Explore career opportunities using U.S. Bureau of Labor Statistics data.
    </div>
    """,
    unsafe_allow_html=True
)


# ============================================================
# INTRODUCTION
# ============================================================

st.markdown(
    """
    <div class="info-card">
        <b>How CareerCompass works</b><br><br>
        Ask a career question and CareerCompass will:
        <ul>
            <li>Find relevant occupations using semantic search</li>
            <li>Retrieve supporting BLS occupational information</li>
            <li>Compare states and metropolitan areas</li>
            <li>Use CareerCompass scores to identify locations with stronger
                labor-market indicators</li>
            <li>Generate a natural-language explanation using Gemini</li>
        </ul>
    </div>
    """,
    unsafe_allow_html=True
)


# ============================================================
# USER QUESTION
# ============================================================

st.markdown(
    '<div class="section-title">🔎 Ask CareerCompass</div>',
    unsafe_allow_html=True
)

query = st.text_input(
    "What would you like to know?",
    placeholder="Example: What does a data scientist do?",
    key="career_query"
)


# ============================================================
# RUN CAREER ANALYSIS
# ============================================================

if st.button("🚀 Explore Career", use_container_width=True):

    if not query.strip():
        st.warning("Please enter a career question first.")

    else:

        # ----------------------------------------------------
        # STEP 1 — RETRIEVAL
        # ----------------------------------------------------

        with st.spinner("Searching the CareerCompass knowledge base..."):

            results = retrieve(query, top_k=3)

        if not results:
            st.error(
                "I couldn't find a relevant occupation for that question."
            )
            st.stop()


        # ----------------------------------------------------
        # PRIMARY OCCUPATION
        # ----------------------------------------------------

        primary_occupation = results[0]["OCC_TITLE"]

        st.markdown(
            f"""
            <div class="occupation-badge">
                🎯 Primary occupation: {primary_occupation}
            </div>
            """,
            unsafe_allow_html=True
        )


        # ----------------------------------------------------
        # STEP 2 — CAREERCOMPASS ENGINE
        # ----------------------------------------------------

        with st.spinner(
            f"Analyzing labor-market data for {primary_occupation}..."
        ):

            state_results = get_state_recommendations(primary_occupation)

            msa_results = get_msa_recommendations(primary_occupation)


        # ----------------------------------------------------
        # STEP 3 — GEMINI
        # ----------------------------------------------------

        with st.spinner("Generating your CareerCompass explanation..."):

            # Build retrieval context
            retrieved_context = "\n\n".join(
                [
                    (
                        f"Occupation: {result['OCC_TITLE']}\n"
                        f"Similarity: {result['similarity']:.3f}\n"
                        f"Information: {result['text']}"
                    )
                    for result in results
                ]
            )


            # Keep the context manageable
            state_context = state_results.head(5).to_dict(
                orient="records"
            )

            msa_context = msa_results.head(5).to_dict(
                orient="records"
            )


            career_results = {
                "primary_occupation": primary_occupation,
                "state_recommendations": state_context,
                "msa_recommendations": msa_context
            }


            try:

                answer = generate_answer(
                    query,
                    retrieved_context,
                    career_results
                )

            except Exception as e:

                answer = (
                    "The labor-market analysis was completed, "
                    "but the Gemini explanation could not be generated.\n\n"
                    f"Error: {e}"
                )


        # ====================================================
        # GEMINI ANSWER
        # ====================================================

        st.markdown(
            '<div class="section-title">💡 CareerCompass Analysis</div>',
            unsafe_allow_html=True
        )

        st.markdown(
            f"""
            <div class="info-card">
                {answer}
            </div>
            """,
            unsafe_allow_html=True
        )


        # ====================================================
        # RETRIEVED OCCUPATIONS
        # ====================================================

        st.markdown(
            '<div class="section-title">📚 Retrieved Occupations</div>',
            unsafe_allow_html=True
        )

        retrieval_display = pd.DataFrame(
            [
                {
                    "Occupation": r["OCC_TITLE"],
                    "Similarity": round(r["similarity"], 3)
                }
                for r in results
            ]
        )

        st.dataframe(
            retrieval_display,
            use_container_width=True,
            hide_index=True
        )


        # ====================================================
        # STATE RECOMMENDATIONS
        # ====================================================

        st.markdown(
            '<div class="section-title">🇺🇸 State-Level Career Data</div>',
            unsafe_allow_html=True
        )

        if state_results.empty:

            st.info(
                "No state-level recommendations were available "
                "for this occupation."
            )

        else:

            state_display = state_results.head(10).copy()

            columns_to_show = [
                    "OCC_TITLE",
                    "STATE",
                    "STATE_CODE",
                    "STATE_MEDIAN_WAGE",
                    "STATE_EMPLOYMENT",
                    "LOCATION_QUOTIENT",
                    "PROJECTED_GROWTH_PCT",
                    "ANNUAL_OPENINGS",
                    "CAREERCOMPASS_SCORE"
            ]

            columns_to_show = [
                col
                for col in columns_to_show
                if col in state_display.columns
            ]

            state_display = state_display[columns_to_show]

            # Format values
            if "STATE_MEDIAN_WAGE" in state_display.columns:
                state_display["STATE_MEDIAN_WAGE"] = (
                    state_display["STATE_MEDIAN_WAGE"]
                    .apply(
                        lambda x:
                        f"${x:,.0f}"
                        if pd.notna(x)
                        else "N/A"
                    )
                )

            if "STATE_EMPLOYMENT" in state_display.columns:
                state_display["STATE_EMPLOYMENT"] = (
                    state_display["STATE_EMPLOYMENT"]
                    .apply(
                        lambda x:
                        f"{x:,.0f}"
                        if pd.notna(x)
                        else "N/A"
                    )
                )

            if "PROJECTED_GROWTH_PCT" in state_display.columns:
                state_display["PROJECTED_GROWTH_PCT"] = (
                    state_display["PROJECTED_GROWTH_PCT"]
                    .apply(
                        lambda x:
                        f"{x:.1f}%"
                        if pd.notna(x)
                        else "N/A"
                    )
                )

            if "ANNUAL_OPENINGS" in state_display.columns:
                state_display["ANNUAL_OPENINGS"] = (
                    state_display["ANNUAL_OPENINGS"]
                    .apply(
                        lambda x:
                        f"{x:,.1f}"
                        if pd.notna(x)
                        else "N/A"
                    )
                )

            if "LOCATION_QUOTIENT" in state_display.columns:
                state_display["LOCATION_QUOTIENT"] = (
                    state_display["LOCATION_QUOTIENT"]
                    .apply(
                        lambda x:
                        f"{x:.2f}"
                        if pd.notna(x)
                        else "N/A"
                    )
                )

            if "CAREERCOMPASS_SCORE" in state_display.columns:
                state_display["CAREERCOMPASS_SCORE"] = (
                    state_display["CAREERCOMPASS_SCORE"]
                    .apply(
                        lambda x:
                        f"{x:.2f}"
                        if pd.notna(x)
                        else "N/A"
                    )
                )

            st.dataframe(
                state_display,
                use_container_width=True,
                hide_index=True
            )


        # ====================================================
        # MSA RECOMMENDATIONS
        # ====================================================

        st.markdown(
            '<div class="section-title">🏙️ Metropolitan-Area Data</div>',
            unsafe_allow_html=True
        )

        if msa_results.empty:

            st.info(
                "No metropolitan-area recommendations were available "
                "for this occupation."
            )

        else:

            msa_display = msa_results.head(10).copy()

            columns_to_show = [
                    "OCC_TITLE",
                    "MSA",
                    "STATE_CODE",
                    "MSA_MEDIAN_WAGE",
                    "MSA_EMPLOYMENT",
                    "LOCATION_QUOTIENT",
                    "PROJECTED_GROWTH_PCT",
                    "ANNUAL_OPENINGS",
                    "CAREERCOMPASS_SCORE"
            ]

            columns_to_show = [
                col
                for col in columns_to_show
                if col in msa_display.columns
            ]

            msa_display = msa_display[columns_to_show]

            # Format values
            if "MSA_MEDIAN_WAGE" in msa_display.columns:
                msa_display["MSA_MEDIAN_WAGE"] = (
                    msa_display["MSA_MEDIAN_WAGE"]
                    .apply(
                        lambda x:
                        f"${x:,.0f}"
                        if pd.notna(x)
                        else "N/A"
                    )
                )

            if "MSA_EMPLOYMENT" in msa_display.columns:
                msa_display["MSA_EMPLOYMENT"] = (
                    msa_display["MSA_EMPLOYMENT"]
                    .apply(
                        lambda x:
                        f"{x:,.0f}"
                        if pd.notna(x)
                        else "N/A"
                    )
                )

            if "PROJECTED_GROWTH_PCT" in msa_display.columns:
                msa_display["PROJECTED_GROWTH_PCT"] = (
                    msa_display["PROJECTED_GROWTH_PCT"]
                    .apply(
                        lambda x:
                        f"{x:.1f}%"
                        if pd.notna(x)
                        else "N/A"
                    )
                )

            if "ANNUAL_OPENINGS" in msa_display.columns:
                msa_display["ANNUAL_OPENINGS"] = (
                    msa_display["ANNUAL_OPENINGS"]
                    .apply(
                        lambda x:
                        f"{x:,.1f}"
                        if pd.notna(x)
                        else "N/A"
                    )
                )

            if "LOCATION_QUOTIENT" in msa_display.columns:
                msa_display["LOCATION_QUOTIENT"] = (
                    msa_display["LOCATION_QUOTIENT"]
                    .apply(
                        lambda x:
                        f"{x:.2f}"
                        if pd.notna(x)
                        else "N/A"
                    )
                )

            if "CAREERCOMPASS_SCORE" in msa_display.columns:
                msa_display["CAREERCOMPASS_SCORE"] = (
                    msa_display["CAREERCOMPASS_SCORE"]
                    .apply(
                        lambda x:
                        f"{x:.2f}"
                        if pd.notna(x)
                        else "N/A"
                    )
                )

            st.dataframe(
                msa_display,
                use_container_width=True,
                hide_index=True
            )


        # ====================================================
        # DATA NOTE
        # ====================================================

        st.markdown(
            """
            <div class="info-card">
                <b>📊 About the CareerCompass Score</b><br><br>
                The CareerCompass score combines three location-level
                measures using equal weighting:
                median wage, employment, and location quotient.
                The underlying BLS data and occupational projections
                provide additional career context.
            </div>
            """,
            unsafe_allow_html=True
        )


# ============================================================
# FOOTER
# ============================================================

st.markdown(
    """
    <div class="footer">
        CareerCompass • Built using U.S. Bureau of Labor Statistics
        occupational and labor-market data
    </div>
    """,
    unsafe_allow_html=True
)