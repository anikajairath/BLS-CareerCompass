import pandas as pd


# Load CareerCompass final recommendation tables

state_recommendations = pd.read_csv(
    r"C:\Users\admin\Desktop\BLS Project\cleaned\detailed\careercompass_state.csv"
)

msa_recommendations = pd.read_csv(
    r"C:\Users\admin\Desktop\BLS Project\cleaned\detailed\careercompass_msa.csv"
)


def get_state_recommendations(occupation):

    result = state_recommendations[state_recommendations["OCC_TITLE"] == occupation].copy()

    result = result[result["SCORE_AVAILABLE"] == True]

    result = result.sort_values("CAREERCOMPASS_SCORE", ascending=False)

    return result


def get_msa_recommendations(occupation):

    result = msa_recommendations[msa_recommendations["OCC_TITLE"] == occupation].copy()

    result = result[result["SCORE_AVAILABLE"] == True]

    result = result.sort_values("CAREERCOMPASS_SCORE", ascending=False)

    return result
