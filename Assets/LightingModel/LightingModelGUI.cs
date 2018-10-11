using System;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace UnityEditor
{
    internal class LightingModelGUI : ShaderGUI
    {
        public enum BlendMode
        {
            Opaque,
            Cutout,
            Transparent
        }
        public enum CullMode
        {
            Off,
            Front,
            Back
        }
        public enum BRDFMode
        {                               
            Disney,
            Phong,              
            Blinnphong,         
            Modifiedphong,      
            Stretchedphong,
            Blinn,
            Cooktorrance,       
            DisneyAniso,
            Kajiya,             
            AshikhmanShirley,   
            Walter,             
            Ward,               
            WardIsotropic,
            Edwards,            
            Strauss,
            ClothAshikhmin,
            ClothCharlie,
            ClothUE4,

            BRDFCount
        }

        private static class Styles
        {
            public static string cullingMode = "Culling Mode";
            public static string renderingMode = "Rendering Mode";
            public static string brdfMode = "BRDF Mode";

            public static readonly string[] blendNames = Enum.GetNames(typeof(BlendMode));
            public static readonly string[] cullingNames = Enum.GetNames(typeof(CullMode));
            public static readonly string[] brdfNames = Enum.GetNames(typeof(BRDFMode));
        }

        private static class ShaderVar
        {
            public static string renderMode = "_Mode";
            public static string cullingMode = "_CullMode";
            public static string brdfMode = "_BRDFMode";
        }

        MaterialProperty blendMode = null;
        MaterialProperty cullMode = null;
        MaterialProperty brdfModel = null;
        MaterialEditor m_MaterialEditor;

        Color guiCommonContentColor = GUI.contentColor;
        Color guiCommonBackgroundColor = GUI.backgroundColor;

        Color guiHeadContentColor = Color.white;
        Color guiHeadBackgroundColor = new Color(0.1f, 0.2f, 0.9f, 1.0f);

        public void FindProperties(MaterialProperty[] props)
        {
            blendMode = FindProperty(ShaderVar.renderMode, props, false);
            cullMode = FindProperty(ShaderVar.cullingMode, props, false);
            brdfModel = FindProperty(ShaderVar.brdfMode, props, false);
        }

        public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] props)
        {
            m_MaterialEditor = materialEditor;
            Material material = materialEditor.target as Material;

            FindProperties(props); 

            EditorGUI.BeginChangeCheck();
            {
                //head
                GUI.backgroundColor = guiHeadBackgroundColor;
                GUI.contentColor = guiHeadContentColor;
                EditorGUILayout.BeginVertical();
                GUILayout.Space(4);
                {
                    BlendModePopup();
                    CullModePopup();
                    BRDFModePopup();
                }
                EditorGUILayout.EndVertical();

                //content
                EditorGUILayout.Space();
                GUI.backgroundColor = guiCommonContentColor;
                GUI.contentColor = guiCommonBackgroundColor;
                for (int i = 0; i < props.Length; ++i)
                {
                    if(props[i].flags != MaterialProperty.PropFlags.HideInInspector)
                    {
                        materialEditor.ShaderProperty(props[i], props[i].displayName);
                    }                   
                }

            }
            if (EditorGUI.EndChangeCheck())
            {
                foreach (var obj in materialEditor.targets)
                    MaterialChanged((Material)obj);
            }
        }

        void BlendModePopup()
        {
            if (blendMode == null) return;
            EditorGUI.showMixedValue = blendMode.hasMixedValue;
            var mode = (BlendMode)blendMode.floatValue;

            EditorGUI.BeginChangeCheck();
            mode = (BlendMode)EditorGUILayout.Popup(Styles.renderingMode, (int)mode, Styles.blendNames);
            if (EditorGUI.EndChangeCheck())
            {
                m_MaterialEditor.RegisterPropertyChangeUndo(Styles.renderingMode);
                blendMode.floatValue = (float)mode;
            }

            EditorGUI.showMixedValue = false;
        }
        void CullModePopup()
        {
            if (cullMode == null) return;
            EditorGUI.showMixedValue = cullMode.hasMixedValue;
            var mode = (CullMode)cullMode.floatValue;
            EditorGUI.BeginChangeCheck();
            mode = (CullMode)EditorGUILayout.Popup(Styles.cullingMode, (int)mode, Styles.cullingNames);
            if (EditorGUI.EndChangeCheck())
            {
                m_MaterialEditor.RegisterPropertyChangeUndo(Styles.cullingMode);
                cullMode.floatValue = (float)mode;
            }
            EditorGUI.showMixedValue = false;
        }
        void BRDFModePopup()
        {
            if (brdfModel == null) return;

            EditorGUI.showMixedValue = brdfModel.hasMixedValue;
            var mode = (BRDFMode)brdfModel.floatValue;
            EditorGUI.BeginChangeCheck();
            mode = (BRDFMode)EditorGUILayout.Popup(Styles.brdfMode, (int)mode, Styles.brdfNames);
            if (EditorGUI.EndChangeCheck())
            { 
                m_MaterialEditor.RegisterPropertyChangeUndo(Styles.brdfMode);
                brdfModel.floatValue = (float)mode;

                Material mat = m_MaterialEditor.target as Material;
                if(mat != null)
                {
                    for (int i = 0; i < (int)BRDFMode.BRDFCount; ++i)
                        mat.DisableKeyword("_BRDF_" + ((BRDFMode)i).ToString());
                    mat.EnableKeyword("_BRDF_" + ((BRDFMode)mode).ToString());
                }
            }
            EditorGUI.showMixedValue = false;
        }

        public static void SetupMaterialWithShadowCullMode(Material material, CullMode mode)
        {
            switch (mode)
            {
                case CullMode.Back:
                    material.SetInt(ShaderVar.cullingMode, (int)UnityEngine.Rendering.CullMode.Back);
                    break;
                case CullMode.Front:
                    material.SetInt(ShaderVar.cullingMode, (int)UnityEngine.Rendering.CullMode.Front);
                    break;
                case CullMode.Off:
                    material.SetInt(ShaderVar.cullingMode, (int)UnityEngine.Rendering.CullMode.Off);
                    break;
            }
        }
        public static void SetupMaterialWithBlendMode(Material material, BlendMode blendMode)
        {
            switch (blendMode)
            {
                case BlendMode.Opaque:
                    material.SetOverrideTag("RenderType", "");
                    material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.One);
                    material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.Zero);
                    material.SetInt("_ZWrite", 1);
                    material.DisableKeyword("_ALPHATEST_ON");
                    material.DisableKeyword("_ALPHABLEND_ON");
                    material.renderQueue = (int)UnityEngine.Rendering.RenderQueue.Geometry;
                    break;
                case BlendMode.Cutout:
                    material.SetOverrideTag("RenderType", "TransparentCutout");
                    material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.One);
                    material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.Zero);
                    material.SetInt("_ZWrite", 1);
                    material.EnableKeyword("_ALPHATEST_ON");
                    material.DisableKeyword("_ALPHABLEND_ON");
                    material.renderQueue = (int)UnityEngine.Rendering.RenderQueue.AlphaTest;
                    break;
                case BlendMode.Transparent:
                    material.SetOverrideTag("RenderType", "Transparent");
                    material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.SrcAlpha);
                    material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
                    material.SetInt("_ZWrite", 0);
                    material.DisableKeyword("_ALPHATEST_ON");
                    material.EnableKeyword("_ALPHABLEND_ON");
                    material.renderQueue = (int)UnityEngine.Rendering.RenderQueue.Transparent;
                    break;
            }
        }
        static void MaterialChanged(Material material)
        {
            if (material.HasProperty(ShaderVar.renderMode))
                SetupMaterialWithBlendMode(material, (BlendMode)material.GetInt(ShaderVar.renderMode));

            if (material.HasProperty(ShaderVar.cullingMode))
                SetupMaterialWithShadowCullMode(material, (CullMode)material.GetInt(ShaderVar.cullingMode));
        }
    }

} // namespace UnityEditor
